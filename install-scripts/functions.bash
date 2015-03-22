function replace_block {
	file=$1
	blockname=$2
	newblock=$3

	sedcmd="\\:###${blockname}START:,\\:###${blockname}END:d"
	sed $sedcmd $file > $file.new
	mv $file $file.bak
	mv $file.new $file

	echo "###${blockname}START" >> $file
	echo -e $newblock >> $file
	echo "###${blockname}END" >> $file
}

function replace_line {
	file=$1
        linestart=$2
        newline=$3

        sedcmd="s/^${linestart}.*//g"
        sed $sedcmd $file > $file.new
        mv $file $file.bak
        mv $file.new $file
	echo $newline >> $file
}
