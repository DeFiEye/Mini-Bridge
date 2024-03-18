use starknet::ContractAddress;


#[starknet::interface]
trait IBridgeTo<TContractState> {
    fn setBridgeTo(ref self: TContractState, to: felt252);
}

#[starknet::contract]
mod BridgeTo {
    use starknet::get_caller_address;
    use starknet::ContractAddress;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BridgeTo: BridgeTo,
    }
    #[derive(Drop, starknet::Event)]
    struct BridgeTo {
        from: ContractAddress,
        to: felt252,
    }

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl IBridgeToImpl of super::IBridgeTo<ContractState> {
        fn setBridgeTo(ref self: ContractState, to: felt252) {
            self.emit(
                Event::BridgeTo(
                    BridgeTo {
                        from: get_caller_address(),
                        to: to
                    }
                )
            );
        }


    }

}
