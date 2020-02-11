### Gtk UI aux library for using with UI Builder `Glade`

```d
import gtk.Button;
import gtk.Window;
import gtkui;

void main()
{
    auto ui = new UI;
    ui.addOnQuit({ ui.exitLoop(); });
    ui.runLoop();
}

class UI : MainBuilderUI
{
    mixin GtkBuilderHelper;

    @gtkwidget Window mwindow;
    @gtkwidget Button addbtn;

    @gtksignal void someAction()
    {
        /+ do something +/
    }

    this()
    {
        super(import("main.glade"));
        addbtn.addOnClicked((b) { /+ do something +/ });
        setupMainWindow(mwindow);
    }
}
```

For more information see small (~130 lines with comments) [example](example/app.d)

#### Limitations in signal usage

1. Signals in glade file should not contain `User data`,
otherwise this will crash program.

2. If you want to use parameters from signal method you must be sure of
their count and order, otherwise wrong count or order of parameters
will crash program.

3. Parameter of signal method must be gtk pointers (not wraps from gtkD).