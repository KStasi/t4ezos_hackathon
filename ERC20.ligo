
type balance is record [
    balance : tez;
    allowed : map(address, tez);
]

type balances is map(address, balance);

type storageType is record [
    owner : address;
    name: string;
    totalSupply: tez;
    currentSupply: tez;
    balances: balances;
    rate: nat;
];

type actionTransferFrom is record [
    addrFrom : address;
    addrTo : address;
    amount : tez;
]

type actionTransfer is record [
    addrTo : address;
    amount : tez;
]

type actionBuy is record [
    amount : tez;
]

type actionBalanceOf is record [
    who : address;
]

type actioaAllowance is record [
    addrFrom : address;
    addrTo : address;
]

type action is
| TransferFrom of actionTransferFrom
| Transfer of actionTransfer
| Approve of actionTransfer
| Allowance of actioaAllowance
| Buy of actionBuy
| BalanceOf of actionBalanceOf



function buy(const action : actionBuy ; const s : storageType) : (list(operation) * storageType) is
  block { 
    const availableSupply: tez = s.totalSupply - s.currentSupply;
    if amount  > availableSupply then failwith("Total supply overruned");
    else skip;
    const balancesMap : balances = s.balances;
    const tokensAmount: tez = amount * s.rate;
    s.currentSupply := s.currentSupply + tokensAmount;
    const balanceFromInfo : balance = case balancesMap[sender] of
    | None -> record balance = 0mtz; allowed = ((map end) : map(address, tez)); end
    | Some(b) ->  get_force(sender, balancesMap)
    end;
    const allowed: map(address, tez) = balanceFromInfo.allowed;
    const balance: tez = balanceFromInfo.balance + tokensAmount;
    allowed[sender] := balance; 
    balancesMap[sender] := record 
        balance = balance;
        allowed = allowed;
    end;
    s.balances := balancesMap;
  } with ((nil: list(operation)) , s)

function transferFrom(const action : actionTransferFrom ; const s : storageType) : (list(operation) * storageType) is
  block {
    const balancesMap : balances = s.balances;
    const balanceFromInfo : balance = case balancesMap[sender] of
    | None -> record balance = 0mtz; allowed = ((map end) : map(address, tez)); end
    | Some(b) -> get_force(action.addrFrom, s.balances)
    end;

    const awailableAmount: tez = balanceFromInfo.balance;
    if action.amount > awailableAmount then failwith("The amount isn't awailable")
    else skip;

    const allowedAmont: tez = case balanceFromInfo.allowed[sender] of
    | None -> 0mtz
    | Some(b) -> get_force(sender, balanceFromInfo.allowed)
    end;

    if action.amount > allowedAmont then failwith("The amount isn't awailable")
    else skip;


    const balanceToInfo : balance = case balancesMap[action.addrTo] of
    | None -> record balance = 0mtz; allowed = ((map end) : map(address, tez)); end
    | Some(b) -> get_force(action.addrTo, s.balances)
    end;
    const allowed: map(address, tez) = balanceFromInfo.allowed;
    allowed[sender] :=  allowedAmont - action.amount;
    allowed[action.addrFrom] :=  awailableAmount - action.amount;

    balancesMap[action.addrFrom] := record 
        balance = awailableAmount - action.amount;
        allowed = allowed;
    end;
    balancesMap[action.addrFrom] := record 
        balance = awailableAmount - action.amount;
        allowed = balanceFromInfo.allowed;
    end;
    const allowedTo: map(address, tez) = balanceToInfo.allowed;
    allowedTo[action.addrTo] :=  awailableAmount + action.amount;
    balancesMap[action.addrTo] := record 
        balance = awailableAmount + action.amount;
        allowed = balanceToInfo.allowed;
    end;
    s.balances := balancesMap;
   } with ((nil: list(operation)) , s)


function transfer(const action : actionTransfer ; const s : storageType) : (list(operation) * storageType) is
  block {
        const act: actionTransferFrom = record addrFrom=sender; addrTo=action.addrTo; amount=action.amount end;
   } with transferFrom (act, s)

function balanceOf(const action : actionBalanceOf ; const s : storageType) : (list(operation) * storageType) is
  block { 
      skip
   } with ((nil: list(operation)) , s)

function allowance(const action : actioaAllowance ; const s : storageType) : (list(operation) * storageType) is
  block {
        skip
   } with ((nil: list(operation)) , s)


function approve(const action : actionTransfer ; const s : storageType) : (list(operation) * storageType) is
  block {
    const balancesMap : balances = s.balances;
    const balanceFromInfo : balance = case balancesMap[sender] of
    | None -> record balance = 0mtz; allowed = ((map end) : map(address, tez)); end
    | Some(b) -> get_force(sender, balancesMap)
    end;
    const amount: tez = balanceFromInfo.balance;
    if action.amount < amount then failwith("The amount isn't awailable")
    else skip;
    const allowed:  map(address, tez) = balanceFromInfo.allowed;
    allowed[action.addrTo] := action.amount;
    balancesMap[sender] := record 
        balance = balanceFromInfo.balance;
        allowed = allowed;
    end;
    s.balances := balancesMap;
   } with ((nil: list(operation)) , s)


function main(const action : action; const s : storageType) : (list(operation) * storageType) is 
 block {skip} with 
 case action of
 | Buy (bt) -> buy (bt, s)
 | Transfer (tx) -> transfer (tx, s)
 | TransferFrom (tx) -> transferFrom (tx, s)
 | Approve (at) -> approve (at, s)
 | Allowance (at) -> allowance (at, s)
 | BalanceOf (at) -> balanceOf (at, s)

end

