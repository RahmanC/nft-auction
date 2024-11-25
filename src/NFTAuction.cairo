#[starknet::contract]
mod AuctionContract {
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::Uint256;

    #[storage]
    struct Storage {
        highest_bid: u256,
        highest_bidder: ContractAddress,
        auction_end: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        NewHighestBid: NewHighestBid,
        AuctionEnded: AuctionEnded,
    }

    #[derive(Drop, starknet::Event)]
    struct NewHighestBid {
        bidder: ContractAddress,
        bid_amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct AuctionEnded {
        winner: ContractAddress,
        winning_bid: u256,
    }

    #[external(v0)]
    impl AuctionImpl of super::IAuction<ContractState> {
        fn initialize(ref self: ContractState, duration: u256) {
            let now = starknet::get_block_timestamp();
            self.auction_end.write(now + duration);
            self.highest_bid.write(0); // Initial bid
            self.highest_bidder.write(ContractAddress::zero()); // No bidder at the start
        }

        fn place_bid(ref self: ContractState, bid_amount: u256) {
            let caller = get_caller_address();
            let current_highest_bid = self.highest_bid.read();

            // Ensure auction is still active
            let now = starknet::get_block_timestamp();
            assert(now < self.auction_end.read(), 'Auction ended');

            // Ensure bid is higher than the current highest bid
            assert(bid_amount > current_highest_bid, 'Bid too low');

            // Update highest bid and highest bidder
            self.highest_bid.write(bid_amount);
            self.highest_bidder.write(caller);

            // Emit new highest bid event
            self.emit(Event::NewHighestBid(NewHighestBid { bidder: caller, bid_amount, }));
        }

        fn end_auction(ref self: ContractState) {
            let now = starknet::get_block_timestamp();
            assert(now >= self.auction_end.read(), 'Auction still ongoing');

            // Emit auction ended event
            let winner = self.highest_bidder.read();
            let winning_bid = self.highest_bid.read();
            self.emit(Event::AuctionEnded(AuctionEnded { winner, winning_bid, }));
        }

        fn get_highest_bidder(self: @ContractState) -> ContractAddress {
            self.highest_bidder.read()
        }

        fn get_highest_bid(self: @ContractState) -> u256 {
            self.highest_bid.read()
        }

        fn get_auction_end(self: @ContractState) -> u256 {
            self.auction_end.read()
        }
    }

    #[starknet::interface]
    trait IAuction<TContractState> {
        fn initialize(self: TContractState, duration: u256);
        fn place_bid(self: TContractState, bid_amount: u256);
        fn end_auction(self: TContractState);
        fn get_highest_bidder(self: @TContractState) -> ContractAddress;
        fn get_highest_bid(self: @TContractState) -> u256;
        fn get_auction_end(self: @TContractState) -> u256;
    }
}
