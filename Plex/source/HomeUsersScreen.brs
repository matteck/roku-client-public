function createHomeUsersScreen(viewController as object) as object
    obj = CreateObject("roAssociativeArray")
    initBaseScreen(obj, viewController)

    screen = CreateObject("roListScreen")
    screen.SetMessagePort(obj.Port)
    screen.SetHeader("User Selection")
    obj.screen = screen
    obj.userSelectionScreen = true

    obj.Show = homeusersShow
    obj.HandleMessage = homeusersHandleMessage

    lsInitBaseListScreen(obj)

    return obj
end function

sub homeusersShow()
    ' Use a facade (roImageCanvas) to lock the screens below our stack. We need
    ' to disallow all remote buttons, specificialy the back button.
    if GetGlobal("screenIsLocked") <> invalid and m.facade = invalid then
        facade = CreateObject("roImageCanvas")
        facade.SetLayer(0, {Color:"#ff1f1f1f", CompositionMode:"Source"})
        facade.Show()
        m.facade = facade
    end if

    focusedIndex = 0
    MyPlexManager().UpdateHomeUsers()
    for each user in MyPlexManager().homeUsers
        if tostr(user.protected) = "1" or tostr(user.protected) = "true" then
            user.SDPosterUrl = "file://pkg:/images/lock_192x192.png"
            user.HDPosterUrl = "file://pkg:/images/lock_192x192.png"
        else
            user.SDPosterUrl = "file://pkg:/images/unlock_192x192.png"
            user.HDPosterUrl = "file://pkg:/images/unlock_192x192.png"
        end if

        if tostr(user.admin) = "1" or tostr(user.admin) = "true" then
            user.ShortDescriptionLine1 = "Admin"
        else
            user.ShortDescriptionLine1 = ""
        end if

        if user.id = MyPlexManager().Id then
            focusedIndex = m.contentArray.Count()
        end if
        m.AddItem(user, "user")
    end for

    if GetGlobal("screenIsLocked") <> invalid then
        button = { title: "Exit", command: "exit" }
    else if GetViewController().screens.count() = 1 then
        button = { title: "Exit", command: "close" }
    else
        button = { title: "Close", command: "close" }
    end if
    m.AddItem({title: button.title, SDPosterUrl: "", HDPosterUrl: ""}, button.command)

    m.screen.SetFocusedListItem(focusedIndex)

    m.screen.Show()
end sub

function homeusersHandleMessage(msg as object) as boolean
    handled = false

    if type(msg) = "roListScreenEvent" then
        handled = true

        if msg.isScreenClosed() then
            Debug("Exiting homeusers screen")
            ' Recreate this lock/user screen if still locked, normally due to user pressing back
            if GetGlobal("screenIsLocked") <> invalid then
                GetViewController().CreateLockScreen()
            end if
            if m.facade <> invalid then m.facade.close()
            m.ViewController.PopScreen(m)
            ' close the previous screen if the user was idle on a user selection screen
            screen = m.ViewController.screens.peek()
            if GetGlobal("screenIsLocked") = invalid and screen <> invalid and screen.userSelectionScreen = true then
                screen.screen.close()
            end if
        else if msg.isListItemSelected() then
            command = m.GetSelectedCommand(msg.GetIndex())
            if command = "user" then
                user = m.contentarray[msg.GetIndex()]

                ' check if the user is protected and show a PIN screen (allow admin bypass)
                adminBypassPin = (MyPlexManager().admin = true and MyPlexManager().IsSignedIn and (MyPlexManager().Protected = false or MyPlexManager().PinAuthenticated))
                if NOT adminBypassPin and (tostr(user.protected) = "1" or tostr(user.protected) = "true") then
                    screen = createHomeUserPinScreen(m.ViewController, user.title, user.id)
                    screen.Show()
                    authorized = screen.authorized
                else
                    authorized = MyPlexManager().SwitchHomeUser(user.id)
                    ' Show a warning on switch failure (PIN screen does the same)
                    if NOT authorized then
                        dialog = createBaseDialog()
                        dialog.Title = "User Switch Failed"
                        dialog.Text = "An error occurred while trying to switch users. Please check your connection and try again."
                        dialog.Show(true)
                    end if
                end if

                if authorized then
                    Debug("Remove global screen lock")
                    GetGlobalAA().Delete("screenIsLocked")
                    m.screen.Close()
                end if
            else if command = "close" then
                m.screen.Close()
            else if command = "exit" then
                end
            end if
        end if
    end if

    return handled
end function
