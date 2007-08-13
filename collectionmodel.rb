=begin
  collectionmodel.rb

  Copyright (c) 2007 Daniel Kamiński

  This is free software; you can copy and distribute and modify
  this program under the term of Ruby's License
  (http://www.ruby-lang.org/LINCENSE.txt)

=end

class CollectionModel < Qt::AbstractItemModel

  attr_reader :dalist
  def initialize(xc, *args)
    super(*args)
    @xc=xc
    @dalist=[]
    @columns=[] << "Id" << "Title" << "Artist" << "Album" << "Duration"
  end

  def clear
    beginRemoveRows(Qt::ModelIndex.new, 0, @dalist.size)
    @dalist.clear
    endRemoveRows()
  end
  alias :playlistClear :clear

  def setColl(coll)
    @xc.coll_query_info(coll, %w{id title artist album duration url}) do |res|
      begin
        list=res.value
        clear
        beginInsertRows(Qt::ModelIndex.new, 0, list.size)
        @dalist=list
        endInsertRows()
      rescue StandardError => e
        puts e
      end
    end
  end

  def rowCount(parent)
    return @dalist.size
  end

  def columnCount(parent)
    return 5
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
        return Qt::Variant.new(@dalist[index.row][:id])
      when 1
        if @dalist[index.row][:title]
          return Qt::Variant.new(@dalist[index.row][:title])
        else
          return Qt::Variant.new(@dalist[index.row][:url].split("/")[-1])
        end
      when 2
        return Qt::Variant.new(@dalist[index.row][:artist])
      when 3
        return Qt::Variant.new(@dalist[index.row][:album])
      when 4
        dur=@dalist[index.row][:duration].to_i/1000
        return Qt::Variant.new(dur/3600 == 0 ? "%02d:%02d"%[(dur/ 60) % 60, dur % 60] :
        "%d:%02d:%02d"%[dur/3600, (dur/ 60) % 60, dur % 60])
      end
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
