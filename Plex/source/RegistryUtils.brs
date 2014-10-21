'***********************************************************
' Registry Helper Functions (original + user section helper)
'***********************************************************

Function RegRead(key, section=invalid, default=invalid)
    ' Reading from the registry is somewhat expensive, especially for keys that
    ' may be read repeatedly in a loop. We don't have that many keys anyway, keep
    ' a cache of our keys in memory.
    section = RegGetSectionName(section)

    cacheKey = key + section
    if m.RegistryCache.DoesExist(cacheKey) then return m.RegistryCache[cacheKey]

    value = default
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) then value = sec.Read(key)

    if value <> invalid then
        m.RegistryCache[cacheKey] = value
    end if

    return value
End Function

Sub RegWrite(key, val, section=invalid)
    section = RegGetSectionName(section)

    if val = invalid then
        RegDelete(key, section)
        return
    end if

    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, val)
    m.RegistryCache[key + section] = val
    sec.Flush() 'commit it
End Sub

Sub RegDelete(key, section=invalid)
    section = RegGetSectionName(section)
    sec = CreateObject("roRegistrySection", section)
    sec.Delete(key)
    m.RegistryCache.Delete(key + section)
    sec.Flush()
End Sub

Sub RegDeleteSection(section)
    Debug("*********** Deleting any key associated with section: " + tostr(section))
    flush = false
    section = RegGetSectionName(section)
    sec = CreateObject("roRegistrySection", section)
    keyList = sec.GetKeyList()
    for each key in keyList
        flush = true
        value = sec.Read(key)
        Debug("Delete: " + tostr(key) + " : " + tostr(value))
        sec.Delete(key)
        m.RegistryCache.Delete(key + section)
    end for
    if flush = true then sec.Flush()
End Sub

'***********************************************************
' Unique Registry Helper Functions
'***********************************************************

' append this string to the section key to uniqueness
function RegGetUserKey(userId as string) as string
    return "_u" + userId
end function

' list of prefs that are customized for each user.
function RegGetUniqueSections()
    obj = { preferences: "", filters: ""}
    return obj
end function

' return the section name, converting the required ones to the right format
Function RegGetSectionName(section=invalid as dynamic) as string
    if section = invalid then return "Default"

    if m.userRegPrefs <> invalid and m.userRegPrefs[section] <> invalid then
        return m.userRegPrefs[section]
    else
        return section
    end if

    return section
end function

' call this when switching users and startup
sub RegInitializeUser()
    ' users will use the defaults prefs if: Not signed in, invalid Id, or Admin
    if NOT MyPlexManager().IsSignedIn or MyPlexManager().Admin = true or MyPlexManager().Id = invalid then
        m.userRegPrefs = invalid
        return
    end if

    Debug("Initializing user Id: " + MyPlexManager().Id)
    m.userRegPrefs = RegGetUniqueSections()
    for each key in m.userRegPrefs
        m.userRegPrefs[key] = tostr(key) + RegGetUserKey(MyPlexManager().Id)
    end for
    RegInitialzePrefs(MyPlexManager().Id)
end sub

' initial the user prefs on first run (copy default prefs)
sub RegInitialzePrefs(userId as string)
    userKey = RegGetUserKey(userId)
    if RegRead("IsInitialized", "preferences" + userKey, "false") = "false" then
        Debug("Initializing user prefs for Id: " + MyPlexManager().Id)
        RegWrite("IsInitialized", "true", "preferences" + userKey)
        for each section in RegGetUniqueSections()
            userSection = tostr(section) + userKey
            Debug(" copy section prefs from " + tostr(section) + " to " + tostr(userSection))

            default = CreateObject("roRegistrySection", section)
            user = CreateObject("roRegistrySection", userSection)

            keyList = default.GetKeyList()
            for each key in keyList
                RegWrite(key, default.Read(key), userSection)
            end for
        end for
    end if
end sub

'TODO(rob): we probably need to clean our prefs, but when?
' purge all unique prefs for a userId
sub RegDeleteUserId(userId as string)
    Debug("Purging user " + userId)

    for each section in RegGetUniqueSections()
        print section
        userSection = tostr(section) + RegGetUserKey(userId)
        Debug("    section: " + tostr(userSection))
        old = CreateObject("roRegistrySection", userSection)
        keyList = old.GetKeyList()
        for each key in keyList
            old.Delete(key)
        end for
    end for
    reg = CreateObject("roRegistry")
    reg.Flush() 'write out changes
    m.RegistryCache.Clear() 'just clear the entire cache
end sub
