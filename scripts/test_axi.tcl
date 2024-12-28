create_hw_axi_txn wr_txn [get_hw_axis hw_axi_1] -address C0000000 -data {11111111_22222222_33333333_44444444_55555555_66666666_77777777_88888888} -len 4 -type write
create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address C0000000 -len 4 -type read

run_hw_axi wr_txn
run_hw_axi rd_txn

delete_hw_axi_txn wr_txn
delete_hw_axi_txn rd_txn

create_hw_axi_txn wr_txn [get_hw_axis hw_axi_1] -address C2000000 -data {11111111_22222222_33333333_44444444_55555555_66666666_77777777_88888888} -len 4 -type write
create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address C2000000 -len 4 -type read

run_hw_axi wr_txn
run_hw_axi rd_txn

delete_hw_axi_txn wr_txn
delete_hw_axi_txn rd_txn

create_hw_axi_txn wr_txn [get_hw_axis hw_axi_1] -address C4000000 -data {11111111_22222222_33333333_44444444_55555555_66666666_77777777_88888888} -len 4 -type write
create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address C4000000 -len 4 -type read

run_hw_axi wr_txn
run_hw_axi rd_txn

delete_hw_axi_txn wr_txn
delete_hw_axi_txn rd_txn

create_hw_axi_txn wr_txn [get_hw_axis hw_axi_1] -address C6000000 -data {11111111_22222222_33333333_44444444_55555555_66666666_77777777_88888888} -len 4 -type write
create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address C6000000 -len 4 -type read

run_hw_axi wr_txn
run_hw_axi rd_txn

delete_hw_axi_txn wr_txn
delete_hw_axi_txn rd_txn



create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address C6000000 -len 1 -type read
run_hw_axi rd_txn
delete_hw_axi_txn rd_txn


create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address C6000000 -len 2 -type read
run_hw_axi rd_txn
delete_hw_axi_txn rd_txn


create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address C6000000 -len 3 -type read
run_hw_axi rd_txn
delete_hw_axi_txn rd_txn


create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address C6000000 -len 4 -type read
run_hw_axi rd_txn
delete_hw_axi_txn rd_txn


create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address C6000000 -len 5 -type read
run_hw_axi rd_txn
delete_hw_axi_txn rd_txn


create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address C6000000 -len 2 -type read
run_hw_axi rd_txn
delete_hw_axi_txn rd_txn


create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address C6000008 -len 2 -type read
run_hw_axi rd_txn
delete_hw_axi_txn rd_txn


create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address C6000010 -len 2 -type read
run_hw_axi rd_txn
delete_hw_axi_txn rd_txn


create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address C6000018 -len 2 -type read
run_hw_axi rd_txn
delete_hw_axi_txn rd_txn