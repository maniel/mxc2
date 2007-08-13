=begin
  playlistmodel.rb

  Copyright (c) 2007 Daniel Kamiński

  This is free software; you can copy and distribute and modify
  this program under the term of Ruby's License
  (http://www.ruby-lang.org/LINCENSE.txt)

=end

class PlaylistModel < Qt::AbstractItemModel

  slots "playlistInsert(int, int)", "playlistMove(int, int)", "playlistAdd(int)", "playlistRemove(int)", "playlistShuffle()", "playlistClear()", "reloadPlaylist()"

  attr_reader :playlist

  def initialize(xc, *args)
    super(*args)
    @xc=xc
    @playlist=@xc.playlist
    @dalist=[]
    fillPlaylist
    @columns=[] << "Title" << "Artist" << "Album" << "Duration"
  end

  def fillPlaylist
    playlistClear
    @playlist.entries.notifier do |list|
      list.value.each do |v|
        @xc.handle_meta(v) do |res|
          self.append(res.value)
        end
      end
    end
  end
  alias :playlistShuffle :fillPlaylist
  alias :reloadPlaylist :fillPlaylist

  def clear
    beginRemoveRows(Qt::ModelIndex.new, 0, @dalist.size)
    @dalist.clear
    endRemoveRows()
  end
  alias :playlistClear :clear

  def playlistAdd(id)
    @xc.handle_meta(id) do |res|
      append(res.value)
    end
  end

  def append(dict)
    beginInsertRows(Qt::ModelIndex.new, @dalist.size, @dalist.size+1)
    @dalist << dict
    endInsertRows()
  end

  def playlistInsert(id, pos)
    @xc.handle_meta(id) do |res|
      insert(res.value, pos)
    end
  end

  def insert(dict, pos)
    beginInsertRows(Qt::ModelIndex.new, pos, pos+1)
    @dalist.insert(pos, dict)
    endInsertRows()
  end

  def remove(pos)
    beginRemoveRows(Qt::ModelIndex.new, pos, pos)
    x=@dalist.delete_at(pos)
    endRemoveRows()
    return x
  end
  alias :playlistRemove :remove

  def move(from, to)
    tmp=remove(from)
    insert(tmp, to)
  end

  def rowCount(parent)
    return @dalist.size
  end

  def columnCount(parent)
    return 4
  end

  def index(row, column, parent=Qt::ModelIndex.new)
    return createIndex(row, column)
  end

  def data(index, role)
    return Qt::Variant.new unless index.isValid
    return Qt::Variant.new if @dalist.size <= index.row
    if role == Qt::DisplayRole
      case index.column
      when 0
        if @dalist[index.row][:title]
          return Qt::Variant.new(@dalist[index.row][:title])
        else
          return Qt::Variant.new(@dalist[index.row][:url].split("/")[-1])
        end
      when 1
        return Qt::Variant.new(@dalist[index.row][:artist])
      when 2
        return Qt::Variant.new(@dalist[index.row][:album])
      when 3
        dur=@dalist[index.row][:duration].to_i/1000
        return Qt::Variant.new(dur/3600 == 0 ? "%02d:%02d"%[(dur/ 60) % 60, dur % 60] :
        "%d:%02d:%02d"%[dur/3600, (dur/ 60) % 60, dur % 60])
      end
    elsif role == Qt::ToolTipRole
      info=@dalist[index.row]
      return Qt::Variant.new("<div><b>Artist:</b> #{info[:artist]}</div><div><b>Title:</b> #{info[:title]}")
    else
      return Qt::Variant.new
    end
  end

  def headerData(section, orientation = Qt::Horizontal, role = Qt::DisplayRole)
    return Qt::Variant.new unless role == Qt::DisplayRole
    if orientation==Qt::Horizontal
      return Qt::Variant.new(@columns[section])
    else
      return Qt::Variant.new
    end
  end

  def parent(index)
    return Qt::ModelIndex.new
  end
end

# vim: set ts=2 sw=2
