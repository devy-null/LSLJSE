integer CHAN_SERVER_QUEUE = -6343254;
integer CHAN_PRINT_QUEUE = -6344854;

default
{
    state_entry()
    {
        llListen(1, "", "", "print");
    }
    
    listen(integer chan, string name, key id, string text)
    {
        if (chan == 1 && text == "print") llMessageLinked(LINK_THIS, CHAN_PRINT_QUEUE, "", "");
    }

    touch_start(integer total_number)
    {
        llMessageLinked(LINK_THIS, CHAN_SERVER_QUEUE, "{ \"Test\": 42 }", llGetOwner());
    }
}
