/*
    Simple DAO Contract
    Allows users to vote YES/NO and reset votes
*/

struct SimpleDao {
    queryId: uint32;
    yesVotes: uint32;
    noVotes: uint32;
    totalVotes: uint32;
}

fun SimpleDao.load(): SimpleDao {
    return SimpleDao.fromCell(contract.getData());
}

fun SimpleDao.save(self) {
    contract.setData(self.toCell());
}

struct (0xF4A2B1C9) RecordVote {
    queryId: uint32;
    vote: bool;  
}

struct (0xD4E7B328) ResetVotes {
    queryId: uint32;
}

type AllowedMessage = RecordVote | ResetVotes;

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return;
    }

    val msg = AllowedMessage.fromSlice(in.body);

    match (msg) {
        RecordVote => {
            var dao = SimpleDao.load();
            dao.queryId = msg.queryId;

            if (msg.vote) {
                dao.yesVotes += 1;
            } else {
                dao.noVotes += 1;
            }

            dao.totalVotes += 1;
            dao.save();
        }

        ResetVotes => {
            var dao = SimpleDao {
                queryId: msg.queryId,
                yesVotes: 0,
                noVotes: 0,
                totalVotes: 0
            };
            dao.save();
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    // No action needed
}

get fun getVotes(): (int, int, int) {
    val dao = SimpleDao.load();
    return (dao.yesVotes, dao.noVotes, dao.totalVotes);
}
