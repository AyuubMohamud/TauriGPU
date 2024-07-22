
# Entity: regfile24 
- **File**: regfile24.sv

## Diagram
![Diagram](regfile24.svg "Diagram")
## Ports

| Port name     | Direction | Type              | Description               |
| ------------- | --------- | ----------------- | ------------------------- |
| core_clock_i  | input     | wire logic        | Clock signal              |
| source_i      | input     | wire logic [4:0]  | Source register           |
| source_data_o | output    | wire logic [23:0] | Source register           |
| dest_i        | input     | wire logic [4:0]  | Destination register      |
| data_w_i      | input     | wire logic [23:0] | Data to write to register |
| dest_we_i     | input     | wire logic        | Data write enable         |

## Signals

| Name      | Type       | Description               |
| --------- | ---------- | ------------------------- |
| rf [0:31] | reg [23:0] | 24-bit Register file bank |

## Processes
- register_write: ( @(posedge core_clock_i) )
  - **Type:** always_ff
