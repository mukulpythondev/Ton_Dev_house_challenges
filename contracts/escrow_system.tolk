// EscrowSystem Contract - Fixed for Tolk 1.1
// Supports initialize, request, release, and cancel escrow operations

struct EscrowSystem {
    owner: address;
    recipient: address;
    amount: uint64;
    isReleased: bool;
    isRequested: bool;
}

fun EscrowSystem.load(): EscrowSystem {
    return EscrowSystem.fromCell(contract.getData());
}

fun EscrowSystem.save(self) {
    contract.setData(self.toCell());
}

struct (0xE3D2C1B4) InitializeEscrow {
    queryId: uint32;
    recipient: address;
    amount: uint64;
}

struct (0xF4E3D2C1) RequestFunds {
    queryId: uint32;
}

struct (0xA1B2C3D4) ReleaseFunds {
    queryId: uint32;
}

struct (0xB1C2D3E4) CancelEscrow {
    queryId: uint32;
}

type MessageBody = InitializeEscrow | RequestFunds | ReleaseFunds | CancelEscrow;

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) { return; }

    val msg = MessageBody.fromSlice(in.body);

    match (msg) {
        InitializeEscrow => {
            var escrow = EscrowSystem {
                owner: in.senderAddress,
                recipient: msg.recipient,
                amount: msg.amount,
                isReleased: false,
                isRequested: false
            };
            escrow.save();
        }

        RequestFunds => {
            var escrow = EscrowSystem.load();
            assert(in.senderAddress == escrow.recipient, 101);
            assert(!escrow.isRequested, 102);
            escrow.isRequested = true;
            escrow.save();
        }

        ReleaseFunds => {
            var escrow = EscrowSystem.load();
            assert(in.senderAddress == escrow.owner, 106);
            assert(escrow.isRequested, 108);
            assert(!escrow.isReleased, 109);
            escrow.isReleased = true;
            escrow.save();

            // Send funds to recipient
            val msgCell = beginCell()
                .storeUint(0x10, 6)
                .storeAddress(escrow.recipient)
                .storeCoins(escrow.amount as coins)   // cast uint64 to coins
                .storeUint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1)
                .endCell();

            sendRawMessage(msgCell, 1);
        }

        CancelEscrow => {
            var escrow = EscrowSystem.load();
            assert(in.senderAddress == escrow.owner, 105);
            assert(!escrow.isReleased, 107);
            escrow.isReleased = true;
            escrow.save();

            // Refund to owner
            val msgCell = beginCell()
                .storeUint(0x10, 6)
                .storeAddress(escrow.owner)
                .storeCoins(escrow.amount as coins)   // cast uint64 to coins
                .storeUint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1)
                .endCell();

            sendRawMessage(msgCell, 1);
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    // Optional: handle bounced messages
}

get fun getEscrowDetails(): (address, address, uint64, bool, bool) {
    val escrow = EscrowSystem.load();
    return (escrow.owner, escrow.recipient, escrow.amount, escrow.isReleased, escrow.isRequested);
}
