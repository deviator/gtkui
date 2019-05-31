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
    mixin GtkUIHelper;

    /// parse xml ui and create elements
    protected Builder builder;

    ///
    this(string xml)
    {
        builder = new Builder;
        enforce(builder.addFromString(xml), new GUIException("cannot create ui"));
        setUpGtkWidgetFields();
    }

    /// Use builder for getting objects
    override ObjectG getObject(string name) { return builder.getObject(name); }
}

/// Class for main UI controller
class MainBuilderUI : BuilderUI
{
    mixin GtkUIHelper;

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
    mixin GtkUIHelper;

    ///
    this(string xml) { super(xml); }

    /// For adding by parent controller
    abstract Widget mainWidget() @property;
}