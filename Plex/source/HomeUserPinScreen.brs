'*
'* PinEntryDialog for switching myplex users. Follows some of the same logic as we use for other
'*  dialogs, since this is just a specialized dialog screen. The fact is, to reset a dialog, we
'*  have to create a new one.
'*

function createHomeUserPinScreen(viewController as object, user as string, id as string) as object
    obj = CreateObject("roAssociativeArray")
    initBaseScreen(obj, viewController)

    obj.Show = hupinShow
    obj.HandleMessage = hupinHandleMessage
    obj.Refresh = hupinRefresh

    obj.authorized = false
    obj.id = id
    obj.user = user
    obj.pinError = false

    obj.ScreensToClose = []

    return obj
end function

sub hupinRefresh()
    if m.screen <> invalid then
        overlay = true
        Debug("Overlaying dialog")
        m.ScreensToClose.Unshift(m.Screen)
    else
        overlay = false
    end if

    m.screen = CreateObject("roPinEntryDialog")
    m.screen.SetMessagePort(m.Port)
    if m.pinError then
        m.screen.setTitle(m.user + " pin failure, try again.")
    else
        m.screen.setTitle(m.user + " pin entry")
    end if
    m.screen.addButton(1,"Next")
    m.screen.addButton(2,"Reset")
    m.screen.addButton(0,"Cancel")
    m.screen.SetNumPinEntryFields(4)
    m.screen.EnableBackButton(true)
    m.Screen.EnableOverlay(overlay)

    m.screen.show()
end sub

sub hupinShow()
    m.screenName = "Pin Screen"
    m.ViewController.AddBreadcrumbs(m, invalid)
    m.ViewController.UpdateScreenProperties(m)
    m.viewController.PushScreen(m)

    m.refresh()

    ' Pin Entry is always "blocking", but we run the global event
    ' loop here to process any messages without technically blocking.
    timeout = 0
    while m.ScreenID = m.ViewController.Screens.Peek().ScreenID
        timeout = m.ViewController.ProcessOneMessage(timeout)
    end while
end sub

function hupinHandleMessage(msg) as boolean
    handled = false

    if type(msg) = "roPinEntryDialogEvent" then
        handled = true
        closeScreens = False

        if msg.isScreenClosed() then
            closeScreens = true
            m.ViewController.PopScreen(m)
        else if msg.getIndex() = 2 then
            m.pinError = false
            m.refresh()
        else if msg.getIndex() = 1 then
            m.authorized = MyPlexManager().SwitchHomeUser(m.id, m.screen.pin())
            if m.authorized then
                m.ScreensToClose.Push(m.Screen)
                closeScreens = true
            else
                m.pinError = true
                m.refresh()
            end if
        else if msg.getIndex() = 0
            m.ScreensToClose.Push(m.Screen)
            closeScreens = true
        end if

        if closeScreens then
            for each screen in m.ScreensToClose
                screen.Close()
            next
            m.ScreensToClose.Clear()
        end if
    end if

    return handled
end function
