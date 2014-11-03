/^class [a-zA-Z]/ {
  mypath = FILENAME
  if ($2 ~ /\(/ || $3 == "(") {
   do 
     if (getline) { 
       if ($1 !~ /\)/ && $1 ~ /^\$/) {
         myparam = $1
         sub( /^\/.*\/modules\//, "", mypath)
         sub( /\/manifests\//, "/", mypath )
         sub( /\.pp/, "", mypath)
         if ( mypath ~ /\/init/ ) {
           sub( /\/init/, "", mypath)
         }
         gsub( /\//, "::", mypath)
         sub(/\$/, "", myparam)
         sub(/,/, "", myparam)
         print ("$" mypath "::" myparam); 
       }
    }
   while($0 !~ /\)/)
  }
}
