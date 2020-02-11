// basic use of gtkui
import std.conv : to;
import std.stdio : stderr;

// import all needed gtk classes
import gtk.Box; // layout container
import gtk.Button;
import gtk.Label;
import gtk.Widget; // base class for all widgets
import gtk.Window;

import gtkui;

void main()
{
    auto ui = new UI;
    // on close main window exit from gtk.Main loop
    ui.addOnQuit({ ui.exitLoop(); });
    // run gtk.Main loop
    ui.runLoop();
}

// main window (main ui class)
class UI : MainBuilderUI
{
    /+ override method that find `@gtkwidget` fields
       and get instances of those fields from builder
       override method that find `@gtksignal` methods
       and connect those methods in builder
     +/
    mixin GtkBuilderHelper;

    // widgets definition
    @gtkwidget Window mwindow;
    @gtkwidget Box vbox;
    @gtkwidget Button addbtn;

    @gtksignal void clickAdd()
    {
        stderr.writeln("clickAdd signal");
    }

    uint panels_count;

    this()
    {
        enum CUSTOMCSS = ""; // you can customize ui

        // get "main.glade" from string import paths at compile-time
        // you can use run-time loading glade files
        super(import("main.glade"), CUSTOMCSS);

        // widgets automaticaly gets from builder and you
        // can use those without any boilereplate code
        addbtn.addOnClicked((b)
        {
            // create new dynamic part of ui and add this to `vbox`
            auto tmp = new Panel(panels_count++);
            vbox.packEnd(tmp.mainWidget, true, true, 12);
        });

        // add calling `quit()` on hide mwindow 
        // and call `showAll()` for mwindow
        setupMainWindow(mwindow);
    }
}

// part of ui -- `ChildBuilder` have no method for working with
// gtk.Main and used as part of main ui, but have own builder
// and requires a glade file in ctor
class Panel : ChildBuilderUI
{
    mixin GtkBuilderHelper;

    uint idx;

    // child parts 
    Foo!"g1" g1;
    Foo!"g2" g2;

    @gtkwidget Box panelmainbox;

    // as for widgets signals can have namespace
    // at glade file signal should have name "panel.clickG2"
    @gtksignal("panel") void clickG2()
    {
        stderr.writefln("clickG2 signal (from %d)", idx);
    }

    this(uint idx)
    {
        this.idx = idx;
        super(import("panel.glade"));
        g1 = new typeof(g1)(this);
        g2 = new typeof(g2)(this);
    }

    override Widget mainWidget() @property { return panelmainbox; }
}

// `ChildGtkUI` most simplest implementation of GtkUI and can't be used
// independently of some `GtkUI` that provides `getObject` method as parent
class Foo(string NAME) : ChildGtkUI
{
    mixin GtkUIHelper;

    // you can use prefix in glade file for widget names ("g1", and "g2")
    @gtkwidget(NAME)
    {
        Button btn; // "g1.btn" or "g2.btn"
        Label label; // "g1.label" or "g2.label"
    }

    this(GtkUI parent)
    {
        super(parent);
        btn.addOnClicked((b) // some behavior
        { label.setText((label.getText.to!uint + 1).to!string); });
    }
}