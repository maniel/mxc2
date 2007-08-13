=begin
  xclient.rb

  Copyright (c) 2007 Daniel Kamiński

  This is free software; you can copy and distribute and modify
  this program under the term of Ruby's License
  (http://www.ruby-lang.org/LINCENSE.txt)

=end

class Class
  private
  def enum(*args)
    args.each_with_index {|arg, i| const_set(arg.to_s.capitalize, i) }
  end
end

class Xmms::Collection
  enum :CHANGED_ADD, :CHANGED_UPDATE, :CHANGED_RENAME, :CHANGED_REMOVE
end

class XClient <Qt::Object

  slots "on_read(int)", "on_write(int)", "putid(int)", "playback_stop()", "playback_play_pause()", "playlist_next()", "playlist_previous()", "playlist_play(QModelIndex)", "playlist_add(QModelIndex)"

  signals "id_changed(int)", "paused()", "playing()", "stopped()", "playlistClear()", "playlistAdd(int)", "playlistRemove(int)", "playlistMove(int, int)", "playlistInsert(int, int)", "playlistShuffle()", "newPlaylistLoaded()", "collectionAdded(QString, bool)", "collectionUpdated(QString, bool)", "collectionRenamed(QString, QString, bool)", "collectionRemoved(QString, bool)"
  attr :playlist

  def initialize(name, *args)
    super(*args)

    setObjectName name
    $xc=Xmms::Client.new name
    @xc=$xc
    @xc.connect(ENV["XMMS_PATH"])
    @playlist=@xc.playlist

    connect_to_eventloop

    #handling playlist changes
    @xc.broadcast_playlist_changed.notifier do |res|
      hash=res.value
      case hash[:type]
      when Xmms::Playlist::CLEAR
        emit playlistClear()
      when Xmms::Playlist::ADD
        emit playlistAdd(hash[:id])
      when Xmms::Playlist::REMOVE
        emit playlistRemove(hash[:position])
      when Xmms::Playlist::MOVE
        emit playlistMove(hash[:position], hash[:newposition])
      when Xmms::Playlist::INSERT
        emit playlistInsert(hash[:id], hash[:position])
      when Xmms::Playlist::SHUFFLE
        emit playlistShuffle()
      else
        p hash
      end
    end
=begin
    #handling playlist loads
    @xc.broadcast_playlist_loaded.notifier do |res|
      emit newPlaylistLoaded()
    end
=end
    @xc.broadcast_coll_changed.notifier do |res|
      h=res.value
      case h[:type]
      when Xmms::Collection::CHANGED_ADD
        emit collectionAdded(h[:name], h[:namespace]==Xmms::Collection::NS_PLAYLISTS)
      when Xmms::Collection::CHANGED_UPDATE
        emit collectionUpdated(h[:name], h[:namespace]==Xmms::Collection::NS_PLAYLISTS)
      when Xmms::Collection::CHANGED_RENAME
        emit collectionRenamed(h[:name], h[:newname], h[:namespace]==Xmms::Collection::NS_PLAYLISTS)
      when Xmms::Collection::CHANGED_REMOVE
        emit collectionRemoved(h[:name], h[:namespace]==Xmms::Collection::NS_PLAYLISTS)
      end
    end
    #handling playback status changes
    @xc.playback_status.notifier do |res|
      case res.value
      when Xmms::Client::PLAY
        emit playing()
      when Xmms::Client::PAUSE
        emit paused()
      when Xmms::Client::STOP
        emit stopped()
      end
    end
    @xc.broadcast_playback_status.notifier do |res|
      case res.value
      when Xmms::Client::PLAY
        emit playing()
      when Xmms::Client::PAUSE
        emit paused()
      when Xmms::Client::STOP
        emit stopped()
      end
    end

    #handling current id change
    @xc.playback_current_id.notifier do |res|
      emit id_changed(res.value) unless res.value==0
    end
    @xc.broadcast_playback_current_id.notifier do |res|
      emit id_changed(res.value)
    end
  end

  def connect_to_eventloop
    @rsock=Qt::SocketNotifier.new(@xc.io_fd, Qt::SocketNotifier::Read, self)
    connect(@rsock, SIGNAL("activated(int)"), SLOT("on_read(int)"))
    @rsock.enabled=true

    @wsock=Qt::SocketNotifier.new(@xc.io_fd, Qt::SocketNotifier::Write, self)
    connect(@wsock, SIGNAL("activated(int)"), SLOT("on_write(int)"))
    @wsock.enabled=false

    @xc.io_on_need_out do
      if @xc.io_want_out
        @rsock.enabled=false
        @wsock.enabled=true
      else
        @rsock.enabled=true
        @wsock.enabled=false
      end
    end
  end

  def handle_meta id, &block
    if block_given?
      @xc.medialib_get_info(id).notifier(&block)
    else
      return @xc.medialib_get_info(id).wait.value
    end
  end

  def get_collections(&block)
    if block_given?
      @xc.coll_list("Collections").notifier(&block)
    else
      return @xc.coll_list("Collections").wait.value
    end
  end

  def get_playlists(&block)
    if block_given?
      @xc.coll_list("Playlists").notifier(&block)
    else
      return @xc.coll_list("Playlists").wait.value
    end
  end

  def coll_query_info(coll, ary, &block)
    if block_given?
      @xc.coll_query_info(coll, ary).notifier(&block)
    else
      return @xc.coll_query_info(coll, ary).wait.value
    end
  end

  def coll_get(coll, &block)
    if block_given?
      @xc.coll_get(coll).notifier(&block)
    else
      return @xc.coll_get(coll).wait.value
    end
  end

  def playback_stop
    @xc.playback_stop.notifier {}
  end

  def playback_play_pause
    @xc.playback_status.notifier do |res|
      if res.value==Xmms::Client::PLAY
        @xc.playback_pause.notifier {}
      else
        @xc.playback_start.notifier {}
      end
    end
  end

  def playlist_add(id)
    @xc.playlist.add_entry(id)
  end

  def playlist_play(index)
    @xc.playlist_set_next(index.row).notifier do
      @xc.playback_tickle.notifier {}
      @xc.playback_status.notifier do |res|
        @xc.playback_start.notifier {} unless res.value == Xmms::Client::PLAY
      end
    end
  end

  def playlist_remove(index)
    @xc.playlist.remove_entry(index.row).notifier {}
  end

  def playlist_next
    @xc.playlist_set_next_rel(1).notifier do
      @xc.playback_tickle.notifier {}
    end
  end

  def playlist_previous
    @xc.playlist_set_next_rel(-1).notifier do
      @xc.playback_tickle.notifier {}
    end
  end

  def on_write i
    return if !@xc.io_out_handle
  end

  def on_read i
    return if !@xc.io_in_handle
  end
end

# vim: set ts=2 sw=2
