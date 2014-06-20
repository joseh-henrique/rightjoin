DIR = "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
find $DIR  -iname "*.csv" -exec rm '{}' ';'
