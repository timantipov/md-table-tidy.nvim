
# Demo of md-table-tidy.nvim plugin

|1|2|3|4|
|-|:-|-:|:-:|
|1|1|1|1|
|2|2|2|2|
|3|3|3|3|
|4|4|4|4|
Treesitter interprets this line as part of the table

|type| from | to |
|:--:| --:|:--- |
|int8| 128 | 127 |
|int16| 32 768 | 32 767 |
|int32| 2 147 483 648| 2 147 483 647|
|int64| 9 223 372 036 854 775 808|9 223 372 036 854 775 807|
|uint8| 0 | 255 |
|uint16| 0 | 65 535 |
|uint32| 0 | 4 294 967 295|
|uint64|  0 | 18 446 744 073 709 551 615|
