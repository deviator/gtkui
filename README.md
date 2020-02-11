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

For more information see small (120 lines with comments) [example](example/app.d) 

#### Limitations in signal usage

1. Signals in glade file should not contain `User data`,
otherwise this will crash program.

2. Signal methods in builder should not receive parameters.