module bank::bank{
    use sui::object::{UID,Self};
    use sui::tx_context::{TxContext,Self};
    use sui::transfer;
    use sui::dynamic_object_field as ofield;


    struct Bank has key {
	id: UID,
	wallets_created: u64,
	users_created: u64,
    }

    struct Wallet has key, store {
	id: UID,
	symbol: vector<u8>,
	balance: u64,
    }

    struct User has key, store {
	id: UID,
	wallet: Wallet,
	intended_address: address,
    }

    fun init(ctx: &mut TxContext) {
	let bank = Bank{
	    id: object::new(ctx),
	    wallets_created: 0,
	    users_created: 0,
	};

	transfer::transfer(bank, tx_context::sender(ctx));
    }

    public entry fun create_wallet(bank: &mut Bank,symbol: vector<u8>, balance: u64, ctx: &mut TxContext) {

	let wallet = Wallet{id: object::new(ctx),
	    symbol,
	    balance,
	};
	bank.wallets_created = bank.wallets_created + 1;
	transfer::transfer(wallet, tx_context::sender(ctx));
    }

    /////////////////////////////////////          wrap              ///////////////////////////////////////////////////////////////////////////////////////////////
    
    public entry fun reqest_wallet(bank: &mut Bank, intended_address: address, wallet: Wallet, ctx: &mut TxContext) {
	let user = User{
	    id: object::new(ctx),
	    wallet,
	    intended_address,
	};
	bank.users_created = bank.users_created + 1;
	transfer::transfer(user, intended_address);
    }

    public entry fun unpack_wallet(user: User, ctx: &mut TxContext) {
	let User {
	    id,
	    wallet,
	    intended_address: _,
	} = user;

	transfer::transfer(wallet, tx_context::sender(ctx));
	object::delete(id);
    }


    ////////////////////////////////////        dynamic                /////////////////////////////////////////////////////////////////


    public entry fun mutable_symbol_wallet(wallet: &mut Wallet, symbol: vector<u8>) {
	wallet.symbol = symbol;
    }

    public fun add_new_wallet(user: &mut User, wallet: Wallet, name: vector<u8>) {
	ofield::add(&mut user.id, name, wallet);
    }

    public entry fun mutate_symbol_wallet_via_user(user: &mut User, wallet_name: vector<u8>, symbol: vector<u8>) {
        mutable_symbol_wallet(ofield::borrow_mut<vector<u8>, Wallet>(
            &mut user.id,
            wallet_name,
        ), symbol);
    }

    public entry fun delete_wallet(user: &mut User, wallet_name: vector<u8>) {
	let Wallet { id,
	    symbol: _,
	    balance: _
	} = ofield::remove<vector<u8>, Wallet>(
            &mut user.id,
            wallet_name,
	);
	object::delete(id);
    }

    public entry fun reclaim_wallet(user: &mut User, wallet_name: vector<u8>, ctx: &mut TxContext) {
	let wallet = ofield::remove<vector<u8>, Wallet>(
            &mut user.id,
            wallet_name,
	);

	transfer::transfer(wallet, tx_context::sender(ctx));
    }

}
