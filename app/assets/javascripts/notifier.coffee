class Notifier
  constructor: ->
    @enableNotification = false
    @checkOrRequirePermission()

  hasSupport: ->
    window.Notification? or window.webkitNotifications? or (window.external && window.external.msIsSiteMode?() isnt undefined)

  requestPermission: (cb) ->
    if @hasSupport()
      return
    if window.webkitNotifications && window.webkitNotifications.checkPermission
      window.webkitNotifications.requestPermission(cb)
    else if window.Notification && window.Notification.requestPermission
      window.Notification.requestPermission(cb)


  setPermission: =>
    if @hasPermission()
      $('#notification-alert a.close').click()
      @enableNotification = true

  hasPermission: ->
    if window.webkitNotifications?
      if window.webkitNotifications.checkPermission() is 0
        return true
      else
        return false
    else if window.Notification?.permission
      if window.Notification.permission is "granted"
        return true
      else
        return false
    else if window.external.msIsSiteMode()
      return true
    else
      return false

  checkOrRequirePermission: =>
    if @hasSupport()
      if @hasPermission()
        @enableNotification = true
      else
        @showTooltip()
    else
      console.log("Desktop notifications are not supported for this Browser/OS version yet.")

  showTooltip: ->
    $('.breadcrumb').before("<div class='alert alert-info' id='notification-alert'><a href='#' id='link_enable_notifications' style='color:green'>点击这里</a> 开启桌面提醒通知功能。 <a class='close' data-dismiss='alert' href='#'>×</a></div>")
    $("#notification-alert").alert()
    $('#notification-alert').on 'click', 'a#link_enable_notifications', (e) =>
      e.preventDefault()
      @requestPermission(@setPermission)

  visitUrl: (url) ->
    window.location.href = url

  notify: (avatar, title, content, url = null) ->
    if @enableNotification
      if not window.Notification
        popup = window.webkitNotifications.createNotification(avatar, title, content)
        if url
          popup.onclick = ->
            window.parent.focus()
            $.notifier.visitUrl(url)
      else
        opts =
          body : content
          onclick : ->
            window.parent.focus()
            $.notifier.visitUrl(url)
        popup = new window.Notification(title,opts)
      popup.show()


jQuery.notifier = new Notifier
