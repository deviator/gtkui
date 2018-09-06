///
module gtkui.exception;

///
class GUIException : Exception
{
    this(string msg, string file=__FILE__, size_t line=__LINE__)
        pure nothrow @nogc @safe 
    { super(msg, file, line); }
}