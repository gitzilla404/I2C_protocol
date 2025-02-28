module i2c_slave(
                  inout sda ,
                  input scl
);

    parameter addresss_slave = 7'b0000001;  // giving  random address to the slave
    parameter read_addr_state = 0;
    parameter send_ack_state = 1;
    parameter write_data_state = 3;
    parameter send_data_state = 4;

    reg [7:0] addr;
    reg [7:0] counter ;
    reg [7:0] state = 0 ;
    reg [7:0] data_in =0 ;
    reg [7:0] data_out =0; // giving data to the master 
    reg sda_out = 0;
    reg sda_in = 0;
    reg wr_enb = 0;
    reg start = 0;

    assign sda = (wr_enb==1)?sda_out : 'bz;

    always @(negedge sda) begin     // negedge indicates start state of slave

        if((start==0) && scl == 1)
            begin
              start <= 1;
              counter<=7;
            end

        
    end
    always @(posedge sda) begin

            if(start==1 && scl==1) 
                begin
                  state<= read_addr_state;
                  start<=0;
                  wr_enb<=0;

                end
    end

//logic for next state.....

    always @(posedge scl ) begin
        if(start == 1)
            begin
              case (state)
                read_addr_state:
                    begin
                      addr[counter]<=sda;
                      if(counter==0)
                        state<=send_ack_state;
                    else
                        counter <= counter-1;
                    end 
                send_ack_state:
                    begin
                      if(addr[7:1]==addresss_slave)
                        begin
                          counter<=7;
                          if(addr[0]== 0)
                            begin
                                state<= read_data_state;
                            end
                        else
                            state <= write_data_state;

                        end

                    end
                read_data_state:
                    begin
                      data_in[counter] <= sda;
                      if(counter ==0)
                        state<=send_ack_2_state;
                    else 
                        counter<= counter-1;
                    end
                send_ack_2_state:
                    begin
                     state<= read_addr_state;
                    end
                write_data_state:
                    begin
                      if(counter == 0)
                        state<= read_addr_state;
                      else  
                        counter = counter-1;
                    end
              endcase
            end
    end

    // logic for assigning the output ....

    always @(negedge scl) begin
        case(state )
        read_addr_state:
            begin
              wr_enb<=0;
            end
        send_ack_state:
            begin
              sda_out<=0;
              wr_enb <=1;

            end
        read_data_state:
            wr_enb<=0;
        send_ack_2_state:
            begin
              sda_out<=0;
              wr_enb<=1;
            end
            write_data_state:
                sda_out<=data_out[counter];
        endcase
        
    end
endmodule 
