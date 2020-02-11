/// Use gtk.Builder for loading interface
module gtkui.builder;

import std.experimental.logger;
import std.exception : enforce;

import gtk.Builder;
import gtk.Widget;
import gtk.Window;
import gobject.ObjectG;

import gtkui.base;
import gtkui.exception;

///
abstract class BuilderUI : GtkUI
{
    /// For `@gtksignal` UDA
    protected struct SignalUDA { string ns; bool swapped; }
    /// ditto
    static protected auto gtksignal(string ns="", bool swapped=false) @property
    { return SignalUDA(ns, swapped); }
    /// ditto
    static protected auto gtksignal(bool swapped) @property
    { return SignalUDA("", swapped); }

    mixin GtkUIHelper;

    /// parse xml ui and create elements
    protected Builder builder;

    /++ Insert this mixin in all builder classes where need use signals
        contains:
            implementation of `void setUpGtkSignals()`
            static extern(C) callback's for signals
     +/
    mixin template GtkBuilderHelper()
    {
        mixin GtkUIHelper;

        import std.traits : hasUDA;

        alias This = typeof(this);

        private static string[] signatureNames(string m)()
        {
            import std.format : format;
            alias F = __traits(getMember, This, m);
            string[] ret;
            foreach (i, p; Parameters!F)
                ret ~= format!"p%d"(i);
            return ret;
        }

        import std.string : join;
        import std.traits : Parameters;

        private static string getSignature(string m)()
        {
            import std.traits : getUDAs;
            import std.algorithm : map;
            import std.range : enumerate;
            import std.format : format;
            enum swapped = getUDAs!(__traits(getMember, This, m), SignalUDA)[0].swapped;
            enum sNames = signatureNames!m;
            enum params = sNames.length ?
                sNames.enumerate.map!(a=>"Parameters!("~m~")["~a.index.to!string~"] "~a.value).join(", ")
                : `void* obj`;
            return swapped ? `void* user_data, `~params : params~`, void* user_data`;
        }

        static foreach (m; __traits(allMembers, This))
        {
            static if (hasUDA!(__traits(getMember, This, m), SignalUDA))
            {
                mixin(`protected static extern(C) void __g_signal_callback_`~m~`(`~getSignature!m~`)
                {
                    import gtkui.exception;
                    import std.exception : enforce;

                    auto t = enforce(cast(This)(user_data),
                        new GUIException("user data pointer for signal '`~m~`' is not '`~This.stringof~`'"));
                    t.`~m~`(`~signatureNames!(m).join(", ")~`);
                }`);
            }
        }

        protected override void setUpGtkSignals()
        {
            import std.traits : getUDAs, isCallable;

            static foreach (m; __traits(allMembers, This))
            {
                static if (hasUDA!(__traits(getMember, This, m), SignalUDA))
                {{
                    static if (!isCallable!(__traits(getMember, This, m)))
                        static assert(0, "signal can be only callable object (field '"~m~"')");
                    enum uda = getUDAs!(__traits(getMember, This, m), SignalUDA)[0];
                    enum name = (uda.ns.length ? uda.ns ~ "." : "") ~ m;
                    mixin(`builder.addCallbackSymbol(name, cast(GCallback)(&__g_signal_callback_`~m~`));`);
                }}
            }
            builder.connectSignals(cast(void*)this);
        }
    }

    ///
    this(string xml)
    {
        builder = new Builder;
        enforce(builder.addFromString(xml), new GUIException("cannot create ui"));
        setUpGtkWidgetFields();
        setUpGtkSignals();
    }

    ///
    protected void setUpGtkSignals() {}

    /// Use builder for getting objects
    override ObjectG getObject(string name) { return builder.getObject(name); }
}

/// Class for main UI controller
class MainBuilderUI : BuilderUI
{
    import glib.Idle;
    static import gtk.Main;
    alias GtkMain = gtk.Main.Main;

protected:
    static bool __gtk_inited = false;

    /// run Main.init with empty args by default
    static void initializeGtk(string[] args=[])
    {
        if (__gtk_inited) return;
        __gtk_inited = true;
        GtkMain.init(args);
    }

    ///
    void delegate()[] onQuitList;

    ///
    void quit() { foreach(dlg; onQuitList) dlg(); }

public:

    ///
    Idle[] idles;

    ///
    void addOnIdle(void delegate() fnc)
    { idles ~= new Idle({ fnc(); return true; }); }

    ///
    void runLoop() { GtkMain.run(); }

    ///
    bool loopStep(bool block=false)
    { return GtkMain.iterationDo(block); }

    ///
    void exitLoop() { GtkMain.quit(); }

    ///
    void addOnQuit(void delegate() dlg) { onQuitList ~= dlg; }

    ///
    protected static string lastUsedCss;

    ///
    static void updateStyle(string css, bool throwOnError=false)
    {
        import gtk.CssProvider;
        import gdk.Screen;
        import gtk.StyleContext;
        import std.typecons : scoped;

        if (css != lastUsedCss)
        {
            lastUsedCss = css;
            try
            {
                auto prov = scoped!CssProvider;
                prov.loadFromData(css);

                StyleContext.addProviderForScreen(Screen.getDefault(),
                        prov, GTK_STYLE_PROVIDER_PRIORITY_USER);
            }
            catch (Throwable e)
            {
                .error("error while loading style: ", e.msg);
                if (throwOnError) throw e;
            }
        }
    }

    ///
    this(string xml, string css="")
    {
        initializeGtk();
        super(xml);
        if (css.length)
            updateStyle(css);
    }

    /++
        add on hide calling quit method
     +/
    void setupMainWindow(Window w)
    {
        w.addOnHide((Widget){ quit(); });
        w.showAll();
    }
}

/// For child UI controllers
class ChildBuilderUI : BuilderUI
{
    ///
    this(string xml) { super(xml); }

    /// For adding by parent controller
    abstract Widget mainWidget() @property;
}