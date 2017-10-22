import std.conv : to;

// import all needed gtk classes
import gtk.Box;
import gtk.Button;
import gtk.Label;
import gtk.Widget;
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
    mixin GtkUIHelper;

    // widgets definition
    @gtkwidget
    {
        Window mwindow;
        Box vbox;
        Button addbtn;
    }

    this()
    {
        enum CUSTOMCSS = ""; // you can customize ui

        // get "main.glade" from string import paths at compile-time
        // you can use run-time loading glade files
        super(import("main.glade"), CUSTOMCSS);

        // widget automaticaly gets from builder and you can use
        // thouse without any boilereplate code
        addbtn.addOnClicked((b)
        {
            // create new dynamic part of ui and add this to `vbox`
            auto tmp = new Panel;
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
    mixin GtkUIHelper;

    // child parts 
    Foo!"g1" g1;
    Foo!"g2" g2;

    @gtkwidget Box panelmainbox;

    this()
    {
        super(import("panel.glade"));
        g1 = new typeof(g1)(this);
        g2 = new typeof(g2)(this);
    }

    override Widget mainWidget() @property
    { return panelmainbox; }
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