// clk:    The system clock used for internal operations.
// rst:    Active high reset signal.
// addr_top:    The 7-bit I2C slave address.
// data_in_top:      The 8-bit data to be sent to the slave.
// enable:    A signal to start an I2C transaction.
// rd_wr:    Read/Write control bit (1 for read, 0 for write).
// data_out:   Stores the received data during a read operation.
// ready:     Indicates when the master is idle and can start a new transaction.
// sda:      Bidirectional Serial Data Line for I2C communication.
// scl:        Bidirectional Serial Clock Line for I2C communication.


// idle_state → The master is waiting for the enable signal.
// start_state → Generates the I2C Start condition.
// address_state → Sends the 7-bit slave address + Read/Write bit.
// read_ack_state → Reads acknowledgment (ACK) from the slave.
// write_data_state → Sends data to the slave (for write operations).
// write_ack_state → Reads acknowledgment after writing data.
// read_data_state → Reads data from the slave (for read operations).
// read_ack_2_state → Reads acknowledgment after receiving data.
// stop_state → Generates the I2C Stop condition.



// state: Keeps track of the current state in the I2C transaction.
// temp_addr: Stores the slave address + R/W bit.
// temp_data: Stores the data to be sent.
// counter2: Counts the number of bits sent/received.
// wr_enb: Controls whether the master is writing or reading.
// sda_out: Stores the output data for the SDA line.




module i2c_master( input clk,
                    input rst,
                    input[6:0] addr_top ,
                    input[7:0] data_in_top,
                    input enable,
                    input rd_wr,

                    output reg[7:0] data_out,
                    output wire ready,
                    
                    inout sda,
                    inout scl);

    parameter idle_state = 0 ;
    parameter start_state = 1;
    parameter address_state = 2;
    parameter read_ack_state = 3;
    parameter write_data_state = 4;
    parameter write_ack_state = 5;
    parameter read_data_state= 6;
    parameter read_ack_2_state = 7;
    parameter stop_state = 8;
    parameter div_const = 4;


    reg [7:0] state;
    reg[7:0] temp_addr;
    reg[7:0] temp_data;
    reg[7:0] counter1 =0;
    reg[7:0] counter2 = 0;
    reg wr_enb;  // to decide if slave will erite or read 
    reg sda_out;
    reg i2c_clk;   // where is the initial value....?????????
    reg i2c_scl_enable = 0;


//logic for clk generation ....

always @(posedge clk ) begin
    if(counter1==(div_const/2)-1) 
        begin
            i2c_clk = ~i2c_clk;
            counter1 =0;
        end
    else begin
        counter1 = counter1+1;
    end
end

assign scl = (i2c_scl_enable==0)?1:i2c_clk;

//logic for i2c scl enabel

always@(posedge i2c_clk , posedge rst)
    begin
        if(rst==1)
            i2c_scl_enable <= 0;
        else if(state==idle_state ||  state == start_state ||state == stop_state)
            i2c_scl_enable<=0;
        else    
            i2c_scl_enable <= 1;  //state= reading  state 

    end

    always@(posedge i2c_clk , posedge rst)
        begin
          case(state)
            idle_state:
                    begin
                        if(enable)
                            begin
                                state<=start_state;
                                temp_addr<= {addr_top,read_write};
                                temp_data <= data_in_top;   //assigning data from
                            end
                        else 
                            state < = idle_state;
                        
                    end
            start_state:
                begin
                    counter2 <= 7;  // ????
                    state <= address_state; 
                end
            address_state:
                begin
                    if(counter2 == 0)
                        begin
                          state <= read_ack_state;
                        end
                    else
                        counter2 <= counter2-1;
                end
            read_ack_state:
                begin
                  if(sda == 0)
                    begin                               // why this begin staement removed later......>????
                        counter2 <= 7;
                        if(temp_addr[0]==0)
                            state <= write_data_state;  // write operation
                        else if(temp_addr[0]==1)
                            state <= read_data_state;  // read operation
                        else 
                            state <= read_data_state;
                    

                    end
                else
                    state <= stop_state;
                end
            write_data_state:     
                begin
                  if(counter2 == 0)
                    begin
                        state <= read_ack_2_state;
                    end
                else 
                    counter2 = counter2-1;
                end
            read_ack_2_state:
                begin
                  if(sda==0 && enabel==1)
                    state <= idle_state;
                  else
                    state <= stop_state;
                    
                end
            read_data_state:
                begin
                  data_out[counter2] <= sda;
                  if(counter2 == 0 )
                        state <= write_ack_state;
                else 
                        counter2 <= counter2-1;
                end
            write_ack_state:
                begin
                  state<= stop_state;
                end
            stop_state:
                begin
                  state <= idle_state;
                end
          endcase
        end


        //logic for generating the output signal 
    always @(negedge i2c_clk ,posedge rst) begin
        if(rst==1)
            begin
                wr_enb <=1;
                sda<=1;
            end
        else
            begin
                case(state)
                    start_state: begin
                        wr_enb<=1;
                        sda_out<=0;
                    end
                
                    address_state: 
                        begin
                          sda_out <= temp_addr[counter2];
                        end
                    read_ack_state:
                        begin
                          wr_enb<=0;
                        end
                    write_data_state:
                        begin
                          wr_enb<=1;
                          sda_out<= temp_data[couunter2];
                        end
                    read_data_state:
                        begin
                          wr_enb<=0;
                        end
                    write_ack_state:
                        begin
                          wr_enb <= 1;
                          sda_out <= 0;
                        end
                    stop_state:
                        begin
                          wr_enb<=1;
                          sda_out <= 1;
                        end
                endcase
            end
        
    end


    // logic for sda line .......

    assign sda  = (wr_enb==1)? sda_out:'bz;

    // logic for ready signal....

    assign ready = ((rst==0)&& (state== idle_state)) ? 1:0;


endmodule