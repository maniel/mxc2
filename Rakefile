task :default => :build

desc "build everything"
task :build => ["ui_mxc2.rb", "res_mxc2.rb"]

desc "build interface from mxc2.ui file"
file "ui_mxc2.rb" => ["mxc2.ui"] do
	sh %{rbuic4 mxc2.ui > ui_mxc2.rb}
end

desc "serialize resources to res_mxc2.rb file"
file "res_mxc2.rb" => ["mxc2.qrc", *Dir.glob("images/*")]  do |t|
	sh %{rbrcc mxc2.qrc -compress 9 -o res_mxc2.rb}
end

desc "clean build directory"
task :clean do
	sh %{ rm -f res_mxc2.rb ui_mxc2.rb }
end
