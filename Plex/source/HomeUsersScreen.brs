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
    focusedIndex = 0
    for each user in MyPlexManager().homeUsers
        if tostr(user.protected) = "1" then
            user.SDPosterUrl = "file://pkg:/images/lock_192x192.png"
            user.HDPosterUrl = "file://pkg:/images/lock_192x192.png"
        else
            user.SDPosterUrl = "file://pkg:/images/unlock_192x192.png"
            user.HDPosterUrl = "file://pkg:/images/unlock_192x192.png"
        end if

        if tostr(user.admin) = "1" then
            user.ShortDescriptionLine1 = "Admin"
        else
            user.ShortDescriptionLine1 = ""
        end if

        if user.id = MyPlexManager().Id then
            focusedIndex = m.contentArray.Count()
        end if
        m.AddItem(user, "user")
    end for

    if GetViewController().screens.count() = 1 then
        m.AddItem({title: "Exit", SDPosterUrl: "", HDPosterUrl: ""}, "close")
    else
        m.AddItem({title: "Close", SDPosterUrl: "", HDPosterUrl: ""}, "close")
    end if

    m.screen.SetFocusedListItem(focusedIndex)

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
