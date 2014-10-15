function createHomeUsersScreen(viewController as object) as object
    obj = CreateObject("roAssociativeArray")
    initBaseScreen(obj, viewController)

    screen = CreateObject("roListScreen")
    screen.SetMessagePort(obj.Port)
    screen.SetHeader("User Selection")
    obj.screen = screen

    obj.Show = homeusersShow
    obj.HandleMessage = homeusersHandleMessage

    lsInitBaseListScreen(obj)

    return obj
end function

sub homeusersShow()
    for each user in MyPlexManager().homeUsers
        m.AddItem(user, "user")
    end for
    m.AddItem({title: "Close"}, "close")

    m.screen.Show()
end sub

function homeusersHandleMessage(msg as object) as boolean
    handled = false

    if type(msg) = "roListScreenEvent" then
        handled = true

        if msg.isScreenClosed() then
            Debug("Exiting homeusers screen")
            m.ViewController.PopScreen(m)
        else if msg.isListItemSelected() then
            command = m.GetSelectedCommand(msg.GetIndex())
            if command = "user" then
                user = m.contentarray[msg.GetIndex()]

                ' check if the user is protected and show a PIN screen
                if tostr(user.protected) = "1" then
                    screen = createHomeUserPinScreen(m.ViewController, user.title, user.id)
                    screen.Show()
                    authorized = screen.authorized
                else
                    authorized = MyPlexManager().SwitchHomeUser(user.id)
                end if

                if authorized then
                    m.screen.Close()
                end if
            else if command = "close" then
                m.screen.Close()
            end if
        end if
    end if

    return handled
end function
