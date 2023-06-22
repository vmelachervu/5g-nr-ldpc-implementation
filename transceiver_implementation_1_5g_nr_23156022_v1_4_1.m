% ------------------------------------------------------------------------------------------------------%
%{
    Program name : 5G NR transceiver implementation with CRC and LDPC and segmentation as per 3GPP TS38.212-f20 standard
    eMasters - Communication Systems, IIT, Kanpur
    5G Transceiver Implementation - I
    Roll number : 23156022
    Student Name : Venkateswar Reddy Melachervu    
    email : vmela23@iitk.ac.in
    History:
    V1.0.0  -   Initial complete solution - 05-06-2023    
    V1.2.0  -   User prompt menus added - 05-06-2023
    V1.2.2  -   In-memory table implementation for base graphs, Zc table,finding 
                the min Zc etc. - 05-06-2023
    V1.3.0  -   Asking user for TB length  - inclusion in the user menu 
                prompt - 06-06-2023
    V1.4.0  -   K' integer check, LDPC encode and decode, final 
                touches, etc. - 06-06-2023
    V1.4.1  -   Closing modifications, error injection trhough interative 
                noise power boost, non-segmented logic, in-coherent input size 
                handling etc. - 07-06-2023

    (C) Venkateswar Reddy Melachervu. 2023-2024.
%}
% ------------------------------------------------------------------------------------------------------%

% 3GPP TS38.212-f20 standard constants 
    % transport block length bounds as per 5G NR
    lowerBound = 24;
    upperBound = 319784;    
    BASE_GRAPH_1_NUM = 1;
    BASE_GRAPH_2_NUM = 2;

    
    % 5G NR base graph key-value structures
    % base graph 1  
    BASE_GRAPH_1 = containers.Map();
    BASE_GRAPH_1('R_min_code_rate') = '1/3';
    BASE_GRAPH_1('base_matrix_size') = '46x68';
    BASE_GRAPH_1('K_b_systematic_columns') = 22;
    BASE_GRAPH_1('K_cb_max_info_block_size') = 8448;
    BASE_GRAPH_1('num_non_zero_elements') = 316;
    
    % base graph 2    
    BASE_GRAPH_2 = containers.Map();
    BASE_GRAPH_2('R_min_code_rate') = '1/5';
    BASE_GRAPH_2('base_matrix_size') = '42x62';
    BASE_GRAPH_2('K_b_systematic_columns') = 10;
    BASE_GRAPH_2('K_cb_max_info_block_size') = 3840;
    BASE_GRAPH_2('num_non_zero_elements') = 197;

    % lifting sizes table  
    LIFTING_SIZES_TABLE = containers.Map();
    LIFTING_SIZES_TABLE('0') = [2 4 8 16 32 64 128 256];
    LIFTING_SIZES_TABLE('1') = [3 6 12 24 48 96 192 384];
    LIFTING_SIZES_TABLE('2') = [5 10 20 40 80 160 320];
    LIFTING_SIZES_TABLE('3') = [7 14 28 56 112 224];
    LIFTING_SIZES_TABLE('4') = [9 18 36 72 144 288];
    LIFTING_SIZES_TABLE('5') = [11 22 44 88 176 352];
    LIFTING_SIZES_TABLE('6') = [13 26 52 104 208];
    LIFTING_SIZES_TABLE('7') = [15 30 60 120 240];    
    
% variables 
tb_generator_poly = [];
tb_crc_size = 0;
transport_block_bits_array = [];
bitsArrayAsString = '';
ldpc_decode_iterations = 25; % Decode with maximum no of iteration

% TB length with CRC
B = 0;
% CB CRC length
L = 24;
% total number of segmented code blocks
C = 0;
% base graph matrix to use
base_graph_to_use = 0;
% code block length to use
K_cb = 0;
% net payload
B_prime = 0;
% user selected crc size for CRC computation
selected_crc_size= 0;

% clear the command window
clc;

% add folders and sub-folders in the current working directory path
currentDir = pwd;
addpath(genpath(currentDir));

% Prompt user if he wants to provide transport block
transport_block_bits_array = user_prompt_menu_for_tb_data();
% if tb input data empty, exit
if isempty(transport_block_bits_array)
    disp('Thanks for testing and using this interactive program written by Venkateswar Reddy Melachervu - Roll number:23156022');
    disp('More about me at http://www.linkedin.com/in/vmelachervu');
    return;
end
fprintf('\n');

% Prompt user to choose the 5G NR generator polynomial for TB CRC
[tb_generator_poly, tb_crc_size] = read_user_selection_of_gp_for_crc_calculation();
% if generator poly is empty, exit
if isempty(tb_generator_poly)
    disp('Thanks for testing and using this interactive program written by Venkateswar Reddy Melachervu - Roll number:23156022');
    disp('More about me at http://www.linkedin.com/in/vmelachervu');
    return;
end
fprintf('\n');

% Calculate CRC for the transport block as per 5G NR standard
disp("Now computing the CRC as per 3GPP Standard TS38.212-f2...");
tb_crc_bits = calculate5GNRCRC(transport_block_bits_array,tb_generator_poly);
if isempty(tb_crc_bits)
    disp('Error in computing the CRC - computed CRC is empty. Exiting the system. Please retry.');
    disp('Thanks for testing and using this interactive program written by Venkateswar Reddy Melachervu - Roll number:23156022');
    disp('More about me at http://www.linkedin.com/in/vmelachervu');
    return;
end
fprintf('\n');
promptCRC = input("Press any key to continue...");

% Prompt user to choose the 5G NR generator polynomial for segmentation CRC GP
[seg_crc_generator_poly, seg_crc_length] = get_user_choice_of_segmentation_gp_crc_with_length();
if seg_crc_length == 0
    disp('Thanks for testing and using this interactive program written by Venkateswar Reddy Melachervu - Roll number:23156022');
    disp('More about me at http://www.linkedin.com/in/vmelachervu');
    return;
end
fprintf('\n');

% Compute B - TB length plus selected TB CRC length
B = (length(transport_block_bits_array)) + tb_crc_size;

% setting the selected base graph and code block length global variables per the base graph selection
base_graph_to_use = user_choice_of_base_graph();
if base_graph_to_use == 0
    disp('Thanks for testing and using this interactive program written by Venkateswar Reddy Melachervu - Roll number:23156022');
    disp('More about me at http://www.linkedin.com/in/vmelachervu');
    return;
end
K_cb = get_segmentation_code_block_length(base_graph_to_use);
fprintf('\n');

% compute total number of code block segments and effective payload
[C, B_prime] = needed_segmentation_code_blocks_and_effective_payload(B, tb_crc_size, K_cb);
fprintf('\n');

% effective paylod bits per code block - K' - K_prime
K_prime = ceil(B_prime/C);
Z_c_min = 0;
i_LS = '';
filler_bits = 0;
K_b = 0;

% find Z_c_min
switch base_graph_to_use
    case BASE_GRAPH_1_NUM    
        K_b = BASE_GRAPH_1('K_b_systematic_columns');
        disp(['The systematic/message columns value for the selected base graph is ' num2str(K_b) ' ...']);
        [Z_c_min, i_LS, filler_bits] = find_min_lifting_size_Z_c_and_filler_bits(LIFTING_SIZES_TABLE, K_b, K_prime);
    case BASE_GRAPH_2_NUM       
        K_b = BASE_GRAPH_2('K_b_systematic_columns');
        disp(['The systematic/message columns value for the selected base graph is ' num2str(K_b) ' ...']);
        [Z_c_min, i_LS, filler_bits] = find_min_lifting_size_Z_c_and_filler_bits(LIFTING_SIZES_TABLE, K_b, K_prime);
end 
if Z_c_min == 0
    disp('Unable to find a valid Z_c in the selected base graph! Exiting the system.');
    disp('Thanks for testing and using this interactive program written by Venkateswar Reddy Melachervu - Roll number:23156022');
    disp('More about me at http://www.linkedin.com/in/vmelachervu');
    return;
end
disp(['The Z_c minimum value found is : ' num2str(Z_c_min)]);
disp(['The lifting index i_ls is : ' i_LS]);
K = K_b*Z_c_min;
disp(['The K (K_b*Z_c_min) is : ' num2str(K)]);
disp(['The K_prime (B_prime/C) is : ' num2str(K_prime)]);
disp(['The number of filler bits (K-K_prime) needed : ' num2str(filler_bits)]);
if (K_prime ~= round(K_prime))
    disp('The selected input TB size resulted in K_prime and filler bits being fractional numbers.');
    disp('This could result in failure of decoded data being not same as transmitted data!');    
end
fprintf('\n');

% create code blocks c_rk and write the data into them from TB
disp('Generating, populating virgin code blocks, computing code block CB-CRCs, appending so computed CB-CRCs along with filler bits...');
% append CRC to the tb data input
b_input_bit_sequence = [ transport_block_bits_array, [tb_crc_bits]]; 
tb_with_crc_length = length(b_input_bit_sequence);
% Map/Hashmap container for storing virgin code blacks {'index', [code block bits]}
c_rk = containers.Map(); 
% running index for filling code blocks with data from TB
s = 1;  
cb_copy_length = K_prime - seg_crc_length;

% let us get noise power from user before modulation
% noise_power = (10^-5); - no error    
% LDPC decoding error lower threshold found to be at around the noise power range of (10^-0.2) - (10^-0.4) 
% for the TB length of 20496 with BG 1    
% noise_power = (10^-5);
disp('Let me get a priori information channel noise power from you.');
noise_power = read_noise_power_from_user();
invalid_user_input = -9999999;
if (noise_power == invalid_user_input)
    disp('Thanks for testing and using this interactive program written by Venkateswar Reddy Melachervu - Roll number:23156022');
    disp('More about me at http://www.linkedin.com/in/vmelachervu');
    loop_error = 1;
    return;
end     
% Index check for copy
collective_seg_data_length = cb_copy_length*C;
if (collective_seg_data_length > length(b_input_bit_sequence))
    disp(['Collective length of the code block segments data (without CB-CRC and filler bits) ' num2str(collective_seg_data_length) ' is greater than (TB + TB-CRC) length ' num2str(tb_with_crc_length) '!']);
    disp('This situation results in error in populating the data across CBs from TB. Exiting the system. Please retry with valid TB size.');
    disp('Thanks for testing and using this interactive program written by Venkateswar Reddy Melachervu - Roll number:23156022');
    disp('More about me at http://www.linkedin.com/in/vmelachervu');
    return;    
end
% for filling in each code block
if (C > 1)
    % segmented logic for TB
    for r = 1 : C 
        % prepare the code block index for the Map - a string index is used for hashmap
        cb_index = num2str((r)); 
        c_rk(cb_index) = [];
        for k = 1 : cb_copy_length
            c_rk(cb_index) = [c_rk(cb_index), [b_input_bit_sequence(s)]];
            s = s + 1;
        end    
        % compute CRC and append CRC and filler bits
        disp(['Computing CB-CRC for code block ' cb_index]);
        cb_crc = calculate5GNRCRC(c_rk(cb_index),seg_crc_generator_poly);
        if isempty(cb_crc)
            disp('Error in computing the code block CB-CRC - computed CB-CRC is empty. Exiting the system. Please retry.');
            disp('Thanks for testing and using this interactive program written by Venkateswar Reddy Melachervu - Roll number:23156022');
            disp('More about me at http://www.linkedin.com/in/vmelachervu');
            return;    
        end    
        c_rk(cb_index) = [c_rk(cb_index), cb_crc, [zeros(1,filler_bits)]];    
    end
else     
    % non-segmented logic for TB
    cb_index = num2str('1'); 
    c_rk(cb_index) = [];
    for k = 1 : tb_with_crc_length
        c_rk(cb_index) = [c_rk(cb_index), [b_input_bit_sequence(s)]];
        s = s + 1;
    end   
    % Even for non-segmented case, when LDPC is used, filler bits are needed to be filled in
    c_rk(cb_index) = [c_rk(cb_index), [zeros(1,filler_bits)]];    
end 

num_of_code_blocks = size(c_rk, 1);
if C> 1
    disp(['Generated and populated code blocks, computed code block CRC and appended so computed CRC along with filler bits to ' num2str(num_of_code_blocks) ' code blocks']);
else
    disp(['Generated and populated code blocks, appended filler bits to ' num2str(num_of_code_blocks) ' code blocks for this non-segmented TB']);
end

% LDPC encode, modulate, demodulate, and decode, validate code blocks
rx_tb_data = [];
loop_error = 0;
if num_of_code_blocks > 1
    % ldpc encoding, modulation, demodulation, and decoding of segmented data
    for r = 1 : C
        cb_index = num2str(r);
        disp(['LDPC encoding code block ' cb_index '...']);
        ldpc_encoded_code_block = double(LDPCEncode(c_rk(cb_index)', base_graph_to_use));   

        disp(['BPSK modulating code block ' cb_index '...']);
        modulated_ldpc_encoded_code_block = 2*(ldpc_encoded_code_block - 0.5);
        
        disp(['Adding some noise to modulated signal of code block ' cb_index '...']);   
        noise = sqrt(noise_power)*randn(size(modulated_ldpc_encoded_code_block));
        rx_code_block_signal = modulated_ldpc_encoded_code_block + noise; 
    
        % Demodulation and LDPC decode
        disp(['BPSK de-modulating code block ' cb_index '...']);
        % BPSK demodulation
        llr0 =  abs(-1 + rx_code_block_signal);   
        llr1 =  abs(1 + rx_code_block_signal);    
        % ldpc decoder requires log(p(r/0)/p(r/1))
        llr = log(llr0./llr1);      
        demodulated_code_block = llr;    
        disp(['LDPC decoding demodulated code block ' cb_index '...']);
        ldpc_decoded_code_block = double(LDPCDecode(demodulated_code_block, base_graph_to_use, ldpc_decode_iterations));
    
        % LDPC decoding and CRC validation of the code blocks    
        errors = find(ldpc_decoded_code_block - (c_rk(cb_index)'));
        if isempty(errors)
            disp(['Successfully decoded LDPC code block ' cb_index '...']);
            disp(['Validating CB-CRC of code block ' cb_index '...']);
            code_block_with_crc = ldpc_decoded_code_block(1:cb_copy_length + seg_crc_length);
            crc_5g_nr_validate(code_block_with_crc', seg_crc_generator_poly);           
            % Concatenate the data across the code blocks
            rx_tb_data = [rx_tb_data, ldpc_decoded_code_block(1:cb_copy_length)'];        
        else
            disp(['LDPC decoding errors found in code block ' cb_index]);   
            disp(['Transmitted data size of code block ' cb_index ' (without CB-CRC and filler bits) is : ' num2str(cb_copy_length)]);   
            disp(['Number of LDPC bit decoding errors found in code block ' cb_index ' : ' num2str(length(errors))]);   
            wait = input("Press any key to continue...");
            disp('Exiting the program. Please retry,');
            disp('Thanks for testing and using this interactive program written by Venkateswar Reddy Melachervu - Roll number:23156022');
            disp('More about me at http://www.linkedin.com/in/vmelachervu');
            loop_error = 1;
            break;
        end           
    end
else
    % ldpc encoding, modulation, demodulation, and decoding of non-segmented data    
    cb_index = '1';
    disp('Processing non-segmented TB data...');
    disp(['LDPC encoding code block ' cb_index '...']);
    ldpc_encoded_code_block = double(LDPCEncode(c_rk(cb_index)', base_graph_to_use));        
    disp(['BPSK modulating code block ' cb_index '...']);
    modulated_ldpc_encoded_code_block = 2*(ldpc_encoded_code_block - 0.5);
    disp(['Adding some noise to modulated signal of code block ' cb_index '...']);   
    noise = sqrt(noise_power)*randn(size(modulated_ldpc_encoded_code_block));
    rx_code_block_signal = modulated_ldpc_encoded_code_block + noise; 

    % Demodulation and LDPC decode
    disp(['BPSK de-modulating code block ' cb_index '...']);
    % BPSK demodulation
    llr0 =  abs(-1 + rx_code_block_signal);   
    llr1 =  abs(1 + rx_code_block_signal);    
    % ldpc decoder requires log(p(r/0)/p(r/1))
    llr = log(llr0./llr1);      
    demodulated_code_block = llr;    
    disp(['LDPC decoding demodulated code block ' cb_index '...']);
    ldpc_decoded_code_block = double(LDPCDecode(demodulated_code_block, base_graph_to_use, ldpc_decode_iterations));

    % LDPC decoding and CRC validation of the code blocks    
    errors = find(ldpc_decoded_code_block - (c_rk(cb_index)'));
    if isempty(errors)
        disp(['Successfully decoded LDPC code block ' cb_index '...']);                
        rx_tb_data = [rx_tb_data, ldpc_decoded_code_block(1:tb_with_crc_length)'];        
    else
        disp(['LDPC decoding errors found in code block ' cb_index]);   
        disp(['Transmitted data size of code block ' cb_index ' (non-segmented) is : ' num2str(tb_with_crc_length)]);   
        disp(['Number of LDPC bit decoding errors found in code block ' cb_index ' : ' num2str(length(errors))]);   
        wait = input("Press any key to continue...");
        disp('Exiting the program. Please retry,');        
        loop_error = 1;            
    end               
end
wait = input("Press any key to continue...");
if ~loop_error
    % Validate TB with decoded and concatenared TB block
    if C > 1
        disp('Now validating TB-CRC of the concatenated segments...');
        display(['The length of desegmented/concatenated TB data received without TB-CRC is ' num2str(length(rx_tb_data) - tb_crc_size)]);
        display(['The length of TB-CRC is ' num2str(tb_crc_size)]);
        display(['The length of desegmented/concatenated TB data received with TB-CRC is ' num2str(length(rx_tb_data))]);        
    else
        disp('Now validating the non-segmented (single segment) TB-CRC...');
        display(['The length of single segment TB data received without TB-CRC is : ' num2str(length(rx_tb_data) - tb_crc_size)]);
        display(['The length of TB-CRC is : ' num2str(tb_crc_size)]);
        display(['The length of filler bits in TB is : ' num2str(filler_bits)]);
        display(['The length of single segment TB data received with TB-CRC and filler bits is : ' num2str(length(rx_tb_data) + filler_bits)]);        
    end    
    crc_5g_nr_validate(rx_tb_data, tb_generator_poly); 
    fprintf('\n');
end 
disp('Little trivia:');
disp('LDPC decoding error lower threshold found around noise power range of (10^-0.1) - (10^-0.4) for 20496 TB length with BG 1 with this program!');
fprintf('\n');
disp('Thanks for testing and using this interactive program written by Venkateswar Reddy Melachervu - Roll number:23156022');
disp('More about me at http://www.linkedin.com/in/vmelachervu');

% ---------------------------------- End of the main program ---------------------------------------------------------------



% ---------------------------------- Begin of functions and utilities ------------------------------------------------------
% utility and computation functions
% Function for reading transport block binary data from user 
function bit_array = read_binary_data()
    binary_string = input('Enter binary data: ', 's');
    bit_array = [];
    for i = 1:length(binary_string)
        if binary_string(i) == '0'
            bit_array = [bit_array, 0];
        elseif binary_string(i) == '1'
            bit_array = [bit_array, 1];
        else
            fprintf('Invalid binary data! Exiting the program. Please retry with valid data.\n');
            bit_array = [];
            return;
        end
    end
end

%Function to validate 5G NR CRC
function crc_5g_nr_validate(receivedMessage, generatorPolynomial)
    % Perform CRC division on the received message
    remainder = crcDivision(receivedMessage, generatorPolynomial);
    
    % Check if the remainder is all zeros (indicating no error)
    if all(remainder == zeros(1, length(remainder)))
        disp('CRC is valid. No error detected.');
    else
        disp('CRC is invalid. Error detected.');
    end    
end

% CRC modulo-2 division fuction
function remainder = crcDivision(message, generatorPolynomial)
    % Perform CRC division using bitwise XOR
    remainder = message;
    divisor = generatorPolynomial;
    
    for i = 1 : length(message) - length(generatorPolynomial) + 1
        if remainder(i)
            remainder(i:i + length(generatorPolynomial) - 1) = bitxor(remainder(i:i + length(generatorPolynomial) - 1), divisor);
        end
    end    
end


% Calculate CRC with padding and return CRC as per 3GPP TS38.212-f20 standard
function calculated5GNRCRC = calculate5GNRCRC(message, generatorPoly)
    % Append padding bits to the data for CRC calculation
    disp("Appending zeros to the data for CRC calculation...");
    numCRCBits = length(generatorPoly) - 1;
    paddedData = [message,zeros(1,numCRCBits)];
    padded_data = sprintf('%d ', paddedData);
    disp(['Padded data is: ' padded_data]);    
    fprintf('\n');

    % Calculating CRC natively
    disp("Calculating CRC natively without any library...");
    remainder = crcDivision(paddedData, generatorPoly);    
    % Extract the CRC bits
    size = length(remainder);
    calculated5GNRCRC = remainder(size - numCRCBits + 1:size);

    % Display calculated CRC bits
    calculated5GNRCRCString = sprintf('%d ', calculated5GNRCRC);
    disp("Calculated CRC bits are:");
    fprintf(calculated5GNRCRCString);
    fprintf('\n');
end

% Selection of base graph and setting the segmented code block length
function [seg_code_block_length] = get_segmentation_code_block_length(selected_base_graph)
    % 5G NR standard values
    BASE_GRAPH_1 = 1;
    BASE_GRAPH_2 = 2;
    K_cb_base_graph_1_cb_length = 8448;
    K_cb_base_graph_2_cb_length = 3840;

    switch selected_base_graph
        case BASE_GRAPH_1           
            % code block length to use
            seg_code_block_length = K_cb_base_graph_1_cb_length;
            disp('Selected base graph is : Base Graph 1');            
        case BASE_GRAPH_2           
            % code block length to use
            seg_code_block_length = K_cb_base_graph_2_cb_length;
            disp('Selected base graph is : Base Graph 2');            
    end
    disp(['Segmentation code block length to be used, if needed : ' num2str(seg_code_block_length)]);
end


% Compute total number of segmentation code blocks from the avaliable user selection
function [needed_code_blocks, effective_pay_load] = needed_segmentation_code_blocks_and_effective_payload(b, l, k_cb)   
    disp(['Transport block length inclusive of the bits for the selected CRC (B) is : ' num2str(b)]);    
    if (b > k_cb)
        needed_code_blocks = ceil(b/(k_cb - l));
        effective_pay_load = b + (needed_code_blocks * l);
        disp(['Segmentation is needed - as B (TB + L) = ' num2str(b) ' is greater than K_cb = ' num2str(k_cb)]);
    else
        needed_code_blocks = 1;
        effective_pay_load = b;
        disp(['Segmentation is NOT needed - as B (TB + L) = ' num2str(b) ' is not greater than K_cb = ' num2str(k_cb)]);
    end
    disp(['Total number of code blocks needed (C) : ' num2str(needed_code_blocks)]);    
    disp(['Effective payload length (B_prime) is : ' num2str(effective_pay_load)]);    
    disp(['K_prime (B_prime/C) is : ' num2str(effective_pay_load/needed_code_blocks)]);    
end

% Function to prompt user for TB data
function transport_block_bits_array = user_prompt_menu_for_tb_data()
    transport_block_bits_array = [];
    % 3GPP standard constants
    lowerBound = 24;
    upperBound = 319784;   
    % Prompt user if he wants to provide transport block
    disp("Welcome to interactive 5G NR transceiver implementation (Matlab Asisgnment - 2 of Cohort-3 EE922) as per 3GPP Standard TS38.212-f20");
    disp("Would you like to type in input tranport block binary data for CRC generation and validation?");
    disp("1. Yes");
    disp("2. No - I want the program to auto generate input transport block data of a specific length");
    disp("3. No - I want the program to auto generate input transport block data between (inclusive) 24 and 3,19,784 bits length");
    disp("4. I am already feeling lucky - that is it and that is all ;-)");
    % Prompt the user for TB data input
    choice = input("Please enter your choice (1-3) : ");
    % Handle the user's choice
    switch choice
        case 1
            disp("You chose to type in the transport block binary data");                
            transport_block_bits_array = read_binary_data();
            if isempty(transport_block_bits_array)
                return;
            else
                bitsArrayAsString = sprintf('%d ', transport_block_bits_array);
                disp('The input transport block binary data you have typed in is :');                        
                disp(bitsArrayAsString);
            end
        case 2
            disp("You chose to let the program auto generate input transport block data of a specific length");  
            tb_length = input("Please enter the TB bit length for auto generating TB data - between 24 and 3,19,784 : ");
            if ((tb_length < lowerBound) || (tb_length > upperBound))
                disp(['You have entered a length value which is illigitimate as per the 3GPP standard - ' num2str(tb_length)]);
                disp('Exiting the program. Please retry with legitimate value.');
                transport_block_bits_array = [];                
                return;
            end
            disp(['Auto generating transport block data of size ' num2str(tb_length) ' bits...']);                                              
            transport_block_bits_array = randi([0, 1], 1, tb_length);
            % bitsArrayAsString = sprintf('%d ', transport_block_bits_array);
            % disp(['Auto generated transport block data is :']);                        
            % disp(bitsArrayAsString);
            disp(['Auto generated transport block data.']);                        
        case 3
            disp("You chose to let the program auto generate random transport block binary data of random size.");  
            disp("Generating random transport block data of random size between 24 and 3,19,784 bits (inclusive) length...");          
            size = randi([lowerBound, upperBound]);               
            disp(['Randomly selected size for the input transmit block is:' num2str(size)]);       
            transport_block_bits_array = randi([0, 1], 1, size);
            bitsArrayAsString = sprintf('%d ', transport_block_bits_array);
            disp('Auto generated transport block data is :');   
            disp(bitsArrayAsString);
        case 4
            disp("You are feeling lucky already! That is it and that is all. Exiting the program...");
            return;        
        otherwise
            disp("Invalid choice. Exiting the program. Please re-run the program and type a number between 1 and 3.");
            return;
    end
end

% Function to prompt user to choose the 5G NR generator polynomial for TB CRC
function [generatorPoly, selected_crc_size] = read_user_selection_of_gp_for_crc_calculation()
    selected_crc_size = 0;
    generatorPoly = [];
    disp('Please select the 5G NR generator polynomial you would like to use for the transport block CRC calculation:');
    disp("1.gCRC24A - 24-bit CRC - [D^24+D^23+D^18+D^17+D^14+D^11+D^10+D^7+D^6+D^5+D^4+D^3+D+1]");
    disp("2.gCRC24B - 24-bit CRC - [D^24+D^23+D^6+D^5+D+1]");
    disp("3.gCRC24C - 24-bit CRC - [D^24+D^23+D^21++D^20+D^17+D^15+D^13+D^12+D^8+D^4+D^2+D+1]");
    disp("4.gCRC16 - 16-bit CRC - [D^16+D^12+D^5+1]");
    disp("5.gCRC11 - 11-bit CRC - [D^11+D^10+D^9+D^5+1]");
    disp("6.gCRC6 - 6-bit CRC - [D^6+D^5+1]");
    disp("7.Exit");
    
    choice = input("Please enter your choice (1-7) : ");
    % Handle the user's choice
    switch choice
        case 1
            disp("You chose option 1 : gCRC24A - 24-bit cyclic generator polynomial for CRC");                         
            generatorPoly = [1 1 0 0 0 0 1 1 0 0 1 0 0 1 1 0 0 1 1 1 1 1 0 1 1];   
            selected_crc_size = length(generatorPoly) - 1;
            generatorPolyString = sprintf('%d ', generatorPoly);
            disp(['Generator polynomial is: ' generatorPolyString]);
        case 2
            disp("You chose option 2 : gCRC24B - 24-bit cyclic generator polynomial");
            generatorPoly = [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 1];   
            selected_crc_size = length(generatorPoly) - 1;
            generatorPolyString = sprintf('%d ', generatorPoly);
            disp(['Generator polynomial is: ' generatorPolyString]);
        case 3
            disp("You chose option 3 : gCRC24C - 24-bit cyclic generator polynomial");
            generatorPoly = [1 1 0 1 1 0 0 1 0 1 0 1 1 0 0 0 1 0 0 0 1 0 1 1 1];   
            selected_crc_size = length(generatorPoly) - 1;
            generatorPolyString = sprintf('%d ', generatorPoly);
            disp(['Generator polynomial is: ' generatorPolyString]);
        case 4
            disp("You chose option 4 : gCRC16 - 16-bit cyclic generator polynomial");
            generatorPoly = [1 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 1];   
            selected_crc_size = length(generatorPoly) - 1;
            generatorPolyString = sprintf('%d ', generatorPoly);
            disp(['Generator polynomial is: ' generatorPolyString]);
        case 5
            disp("You chose option 5 : gCRC11 - 11-bit cyclic generator polynomial");            
            generatorPoly = [1 1 1 0 0 0 1 0 0 0 0 1];
            selected_crc_size = length(generatorPoly) - 1;
            generatorPolyString = sprintf('%d ', generatorPoly);
            disp(['Generator polynomial is: ' generatorPolyString]);
        case 6
            disp("You chose option 6: gCRC6 - 6-bit cyclic generator polynomial");            
            generatorPoly = [1 1 0 0 0 0 1];   
            selected_crc_size = length(generatorPoly) - 1;
            generatorPolyString = sprintf('%d ', generatorPoly);
            disp(['Generator polynomial is: ' generatorPolyString]);
        case 7
            disp("You chose to exit the program. Exiting...");
            return;        
        otherwise
            disp("Invalid choice. Exiting the program. Please re-run the program and type a number between 1 and 7.");
            return;
    end
end 

% Function to prompt user for selecting segmentation CRC polynomial
function [seg_crc_generator_poly, seg_crc_length] = get_user_choice_of_segmentation_gp_crc_with_length()
    seg_crc_length = 0;

    % Prompt user to choose the 5G NR segementation generator polynomial
    disp('Please select 5G NR generator polynomial you would like to use for segemented code blocks:');
    disp("1.gCRC24A - 24-bit CRC - [D^24+D^23+D^18+D^17+D^14+D^11+D^10+D^7+D^6+D^5+D^4+D^3+D+1]");
    disp("2.gCRC24B - 24-bit CRC - [D^24+D^23+D^6+D^5+D+1]");
    disp("3.gCRC24C - 24-bit CRC - [D^24+D^23+D^21++D^20+D^17+D^15+D^13+D^12+D^8+D^4+D^2+D+1]");
    disp("4.gCRC16 - 16-bit CRC - [D^16+D^12+D^5+1]");
    disp("5.gCRC11 - 11-bit CRC - [D^11+D^10+D^9+D^5+1]");
    disp("6.gCRC6 - 6-bit CRC - [D^6+D^5+1]");
    disp("7.Exit");
    
    choice = input("Please enter your choice (1-7): ");    
    % Handle the user's choice
    switch choice
        case 1
            disp("You chose option 1: gCRC24A - 24-bit cyclic generator polynomial for CRC");  
            disp("As per the 3GPP standard, this is an invalid choice of CRC CGP for TB segmentation. ");
            disp("Please re-run the program and select a valid choice for the CGP - one of {gCRC24B, gCRC24C, gCRC16}.");
            disp("Exiting the program.");
            return;           
        case 2
            disp("You chose option 2: gCRC24B - 24-bit cyclic generator polynomial");
            seg_crc_generator_poly = [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 1];   
            seg_crc_length = length(seg_crc_generator_poly) - 1;
            seg_crc_gp_poly_string = sprintf('%d ', seg_crc_generator_poly);
            disp(['Generator polynomial is: ' seg_crc_gp_poly_string]);
        case 3
            disp("You chose option 3: gCRC24C - 24-bit cyclic generator polynomial");
            seg_crc_generator_poly = [1 1 0 1 1 0 0 1 0 1 0 1 1 0 0 0 1 0 0 0 1 0 1 1 1];   
            seg_crc_length = length(seg_crc_generator_poly) - 1;
            seg_crc_gp_poly_string = sprintf('%d ', seg_crc_generator_poly);
            disp(['Generator polynomial is : ' seg_crc_gp_poly_string]);
        case 4
            disp("You chose option 4: gCRC16 - 16-bit cyclic generator polynomial");
            seg_crc_generator_poly = [1 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 1];   
            seg_crc_length = length(seg_crc_generator_poly) - 1;
            seg_crc_gp_poly_string = sprintf('%d ', seg_crc_generator_poly);
            disp(['Generator polynomial is : ' seg_crc_gp_poly_string]);
        case 5
            disp("You chose option 5: gCRC11 - 11-bit cyclic generator polynomial");
            disp("As per the 3GPP standard, this is an invalid choice of CRC CGP for TB segmentation. ");
            disp("Please re-run the program and select a valid choice for the CGP - one of {gCRC24B, gCRC24C, gCRC16}.");
            disp("Exiting the program.");
            return;           
        case 6
            disp("You chose option 6: gCRC6 - 6-bit cyclic generator polynomial");
            disp("As per the 3GPP standard, this is an invalid choice of CRC CGP for TB segmentation. ");
            disp("Please re-run the program and select a valid choice for the CGP - one of {gCRC24B, gCRC24C, gCRC16}.");
            disp("Exiting the program.");
            return;           
        case 7
            disp("You chose to exit the program. Exiting...");
            return;        
        otherwise
            disp("Invalid choice. Exiting the program. Please re-run the program and type a number between 1 and 7.");
            return;
    end
end

% Function to read user choice for the base graph to be used for the segmentation process
function chosen_base_graph = user_choice_of_base_graph()    
    %{
        Base Graph 1 : Optimized for large information block sizes and high code rates - when the SNR is good - K_bc = 8448
        Base Graph 2 : Optimized for smaller information block sizes and lower code rates - when the SNR is lower - K_bc = 3840
    %}
    BASE_GRAPH_1 = 1;
    BASE_GRAPH_2 = 2;    
    chosen_base_graph = BASE_GRAPH_1;
    if chosen_base_graph > BASE_GRAPH_2
        disp('Invalid base graph chosen! Base graph needs to be between 1 and 2. Exiting the system. Please retry with legitimate value.')
        chosen_base_graph = 0;        
        return;
    elseif chosen_base_graph < BASE_GRAPH_1
        disp(['Invalid base graph chosen! Base graph needs to be between 1 and 2. Exiting the system. Please retry with legitimate value.'])
        chosen_base_graph = 0;                    
        return;
    end
end

% Function to find Z_c - minimum lifting size for the parity check matrix needed for LDPC
function [Z_c_min, i_LS, filler_bits] = find_min_lifting_size_Z_c_and_filler_bits(ls_table, K_b, K_prime)           
    % iterate over the map using for loop to find min Z_c
    disp('Iterating over Lifting size table to find minimum Z_c...');
    i_ls_indices = ls_table.keys;
    Z_c_rows = ls_table.values;
    Z_c_min = 0;    
    for i = 1:numel(i_ls_indices)        
        i_ls_current = i_ls_indices{i};
        disp(['Currently searching for legitimate Z_c_min in the row with the index ' num2str(i_ls_current) ' ...']);
        Z_c_current_row = Z_c_rows{i};
        for j = 1:numel(Z_c_current_row)
            Z_c_current = Z_c_current_row(j);             
            if (K_b * Z_c_current) >= K_prime
                disp(['Found a Z_c=' num2str(Z_c_current) ' where ' num2str(K_b) '*' num2str(Z_c_current) '=' num2str(K_b*Z_c_current) ' is greater than or equals to K_prime=' num2str(K_prime)]);
                % initialize Z_c_min with first hit
                if Z_c_min == 0                
                    Z_c_min = Z_c_current;            
                    i_LS = i_ls_current;
                    disp(['The initial Z_c_min hit value is: ' num2str(Z_c_min)]);
                end
                % check if this legitimate Z_c_current is lesser than previous hit
                if (Z_c_current < Z_c_min)
                    disp(['Found this Z_c=' num2str(Z_c_current) ' is less than previously found Z_c=' num2str(Z_c_min)]);
                    Z_c_min = Z_c_current;
                    i_LS = i_ls_current;
                end 
            end 
        end
    end         
    filler_bits = (K_b*Z_c_min) - K_prime;
end

% Read noise power from user
function user_selected_noise_power = read_noise_power_from_user()
    % Prompt user if he/she wants to provide noise power    
    user_selected_noise_power = -9999999;
    disp("Would you like to introduce high channel noise power (format - 10^x, x is a positive or negative finite number) to inject transmission errors?");
    disp("1. Yes");
    disp("2. No - Please use default noise power of 10^-5");    
    disp("3. I am already feeling lucky - that is it and that is all ;-)");
    % Prompt the user for TB data input
    choice = input("Please enter your choice (1-3) : ");
    % Handle the user's choice
    switch choice
        case 1
            disp('Little trivia:');
            disp('LDPC decoding error lower threshold found around noise power range of (10^-0.1) - (10^-0.4) for 20496 TB length with BG 1');
            fprintf('\n');               
            user_noise_power = input("Please enter the power x in 10^x for noise power where x is a positive or negative finite decimal number : ", 's');
            user_noise_power_decimal = str2double(user_noise_power);
            is_valid_decimal = isnumeric(user_noise_power_decimal) && isfinite(user_noise_power_decimal) && mod(user_noise_power_decimal, 1) ~= 0;            
            if ~is_valid_decimal         
                user_selected_noise_power = -9999999;
                disp("Invalid decimal power value for noise power. Exiting the program. Please retry with valid decimal value - x.y or -x.y");                
            else
                user_selected_noise_power = 10^user_noise_power_decimal;
            end             
            return;                        
        case 2
            user_selected_noise_power = 10^-5;
        case 3
            disp("You are feeling lucky already! That is it and that is all. Exiting the program...");
            return;        
        otherwise
            disp("Invalid choice. Exiting the program. Please re-run the program and type a valid choice.");
            return;
    end 
end 