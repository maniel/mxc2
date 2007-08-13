=begin
  trayicon.rb

  Copyright (c) 2007 Daniel Kamiński

  This is free software; you can copy and distribute and modify
  this program under the term of Ruby's License
  (http://www.ruby-lang.org/LINCENSE.txt)

=end

class MXcTrayIcon < Qt::SystemTrayIcon
  slots "show_hide_window()", "activation(QSystemTrayIcon::ActivationReason)", "on_playing()", "on_stopped()", "on_paused()"

  def initialize(*args)
    super(*args)
    setObjectName("trayIcon")
    @icon=Qt::Icon.new(":/images/note.png")
    setIcon(@icon)
    @xc=parent.xc
    @menu=Qt::Menu.new
    setContextMenu(@menu)
    @actions={}
    @actions[:play]=@menu.addAction("Play",@xc, SLOT("playback_play_pause()"))
    @actions[:stop]=@menu.addAction("Stop",@xc, SLOT("playback_stop()"))
    @actions[:next]=@menu.addAction("Next",@xc, SLOT("playlist_next()"))
    @actions[:prev]=@menu.addAction("Prev",@xc, SLOT("playlist_previous()"))
    @menu.addSeparator
    @actions[:show_hide]=@menu.addAction(parent.visible ? "Show":"Hide", self, SLOT("show_hide_window()"))
    @actions[:quit]=@menu.addAction("Quit", $qApp, SLOT("quit()"))

    connect(@xc, SIGNAL("playing()"), self, SLOT("on_playing()"))
    connect(@xc, SIGNAL("paused()"), self, SLOT("on_paused()"))
    connect(@xc, SIGNAL("stopped()"), self, SLOT("on_stopped()"))

    connect(self, SIGNAL("activated(QSystemTrayIcon::ActivationReason)"), SLOT("activation(QSystemTrayIcon::ActivationReason)"))
  end

  def on_playing
    @actions[:play].setText("Pause")
    @actions[:stop].enabled=true
  end

  def on_stopped
    @actions[:play].setText("Play")
    @actions[:stop].enabled=false
  end

  def on_paused
    @actions[:play].setText("Play")
    @actions[:stop].enabled=true
  end

  def activation(reason)
    if reason==Qt::SystemTrayIcon::DoubleClick
      show_hide_window
    end
  end

  def show_hide_window
    if parent.isVisible
      parent.hide
      @actions[:show_hide].setText("Show")
    else
      parent.show
      @actions[:show_hide].setText("Hide")
    end
  end
end

# vim: set ts=2 sw=2
