PERMISSION_DEFAULT = 'default'
PERMISSION_GRANTED = 'granted'
PERMISSION_DENIED = 'denied'
PERMISSION = [
  PERMISSION_GRANTED
  PERMISSION_DEFAULT
  PERMISSION_DENIED
]

class Notifier
  constructor: ->
    @enableNotification = false
    @checkOrRequirePermission()

  hasSupport: ->
    !!(window.Notification or win.webkitNotifications or navigator.mozNotification)

  hasPermission: ->
    if @checkPermission() == PERMISSION_GRANTED
      return true
    else
      return false

  checkPermission: ->
    permission = undefined
    if window.webkitNotifications and window.webkitNotifications.checkPermission
      permission = PERMISSION[window.webkitNotifications.checkPermission()]
    else if navigator.mozNotification
      permission = PERMISSION_GRANTED
    else if window.Notification and window.Notification.permission
      permission = window.Notification.permission
    permission

  checkOrRequirePermission: ->
    if @hasSupport()
      if @hasPermission()
        @enableNotification = true
      else
        if @checkPermission() != PERMISSION_GRANTED
          @askForPermission()
    else
      console.log("Desktop notifications are not supported for this Browser/OS version yet.")

  askForPermission: ->
    if window.webkitNotifications and window.webkitNotifications.checkPermission
      window.webkitNotifications.requestPermission()
    else if window.Notification and window.Notification.requestPermission
      window.Notification.requestPermission()


  notify: (avatar, title, content, url) ->
    console.log avatar
    if @enableNotification
      if not window.Notification
        popup = window.webkitNotifications.createNotification(avatar, title, content)
        if url
          popup.onclick = ->
            window.parent.focus()
            window.location.href = url
        popup.show()
      else
        opts =
          icon: avatar
          body : content
        popup = new window.Notification(title,opts)
        if url
          popup.onclick = ->
            window.parent.focus()
            window.location.href = url
    else
      @checkOrRequirePermission()

# setTimeout ( => popup.cancel() ), 12000

jQuery.notifier = new Notifier