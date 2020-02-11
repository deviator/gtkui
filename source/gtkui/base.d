/// Base types for creating GUI controllers
module gtkui.base;

import gtkui.exception;

import gobject.ObjectG;

/// Base GUI interface type
interface GtkUI
{
    /// For `@gtkwidget` UDA
    protected struct WidgetUDA { string ns; }
    /// ditto
    static protected auto gtkwidget(string ns="") @property
    { return WidgetUDA(ns); }

    /// Automatic initialize `@gtkwidget` fields
    protected void setUpGtkWidgetFields();
    ///
    protected ObjectG getObject(string name);

    /++ Returns:
            casted ui object by name (widget for example)
     +/
    auto ui(T)(string name, string file=__FILE__, size_t line=__LINE__)
        if (is(T : ObjectG))
    {
        import std.format : format;
        import std.exception : enforce;
        auto obj = enforce(getObject(name),
                new GUIException(format("can't get object '%s'", name), file, line));

        return enforce(cast(T)obj,
                new GUIException(format("object '%s' has type '%s', not '%s'",
                        name, obj.getType(), typeid(T).name), file, line));
    }

    /++ Insert this mixin in all child classes where used `@gtkwidget`
        contains:
            implementation of `void setUpGtkWidgetFields()`
     +/
    mixin template GtkUIHelper()
    {
        protected override void setUpGtkWidgetFields()
        {
            import std.traits : hasUDA, getUDAs;
            import std.format : format;
            import gobject.ObjectG;

            alias T = typeof(this);

            foreach (m; __traits(allMembers, typeof(this)))
            {
                static if (hasUDA!(__traits(getMember, T, m), WidgetUDA))
                {
                    enum uda = getUDAs!(__traits(getMember, T, m), WidgetUDA)[0];
                    enum name = (uda.ns.length ? uda.ns ~ "." : "") ~ m;
                    alias F = typeof(__traits(getMember, T, m));
                    static assert(is(F : ObjectG), format("%s is not an ObjectG", F.stringof));
                    __traits(getMember, T, m) = ui!F(name);
                }
            }
        }
    }
}

/// Need parent `GtkUI` for working
class ChildGtkUI : GtkUI
{
    mixin GtkUIHelper;

    ///
    protected GtkUI parent;

    ///
    this(GtkUI parent)
    {
        this.parent = parent;
        setUpGtkWidgetFields();
    }

    ///
    override ObjectG getObject(string name)
    { return parent.getObject(name); }
}