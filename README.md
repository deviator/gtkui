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
    mixin GtkUIHelper;

    @gtkwidget Window mwindow;
    @gtkwidget Button addbtn;

    this()
    {
        super(import("main.glade"));
        addbtn.addOnClicked((b) { /+ do something +/ });
        setupMainWindow(mwindow);
    }
}
```

For more information see small (100 lines with comments) [example](example/app.d) 