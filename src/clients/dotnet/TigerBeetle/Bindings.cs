//////////////////////////////////////////////////////////
// This file was auto-generated by dotnet_bindings.zig  //
//              Do not manually modify.                 //
//////////////////////////////////////////////////////////

using System;
using System.Runtime.InteropServices;

namespace TigerBeetle;

[Flags]
public enum AccountFlags : ushort
{
    None = 0,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#flagslinked
    /// </summary>
    Linked = 1 << 0,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#flagsdebits_must_not_exceed_credits
    /// </summary>
    DebitsMustNotExceedCredits = 1 << 1,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#flagscredits_must_not_exceed_debits
    /// </summary>
    CreditsMustNotExceedDebits = 1 << 2,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#flagshistory
    /// </summary>
    History = 1 << 3,

}

[Flags]
public enum TransferFlags : ushort
{
    None = 0,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#flagslinked
    /// </summary>
    Linked = 1 << 0,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#flagspending
    /// </summary>
    Pending = 1 << 1,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#flagspost_pending_transfer
    /// </summary>
    PostPendingTransfer = 1 << 2,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#flagsvoid_pending_transfer
    /// </summary>
    VoidPendingTransfer = 1 << 3,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#flagsbalancing_debit
    /// </summary>
    BalancingDebit = 1 << 4,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#flagsbalancing_credit
    /// </summary>
    BalancingCredit = 1 << 5,

}

[Flags]
public enum AccountFilterFlags : uint
{
    None = 0,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account-filter#flagsdebits
    /// </summary>
    Debits = 1 << 0,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account-filter#flagscredits
    /// </summary>
    Credits = 1 << 1,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account-filter#flagsreversed
    /// </summary>
    Reversed = 1 << 2,

}

[StructLayout(LayoutKind.Sequential, Size = SIZE)]
public struct Account
{
    public const int SIZE = 128;

    private UInt128 id;

    private UInt128 debitsPending;

    private UInt128 debitsPosted;

    private UInt128 creditsPending;

    private UInt128 creditsPosted;

    private UInt128 userData128;

    private ulong userData64;

    private uint userData32;

    private uint reserved;

    private uint ledger;

    private ushort code;

    private AccountFlags flags;

    private ulong timestamp;

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#id
    /// </summary>
    public UInt128 Id { get => id; set => id = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#debits_pending
    /// </summary>
    public UInt128 DebitsPending { get => debitsPending; internal set => debitsPending = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#debits_posted
    /// </summary>
    public UInt128 DebitsPosted { get => debitsPosted; internal set => debitsPosted = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#credits_pending
    /// </summary>
    public UInt128 CreditsPending { get => creditsPending; internal set => creditsPending = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#credits_posted
    /// </summary>
    public UInt128 CreditsPosted { get => creditsPosted; internal set => creditsPosted = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#user_data_128
    /// </summary>
    public UInt128 UserData128 { get => userData128; set => userData128 = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#user_data_64
    /// </summary>
    public ulong UserData64 { get => userData64; set => userData64 = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#user_data_32
    /// </summary>
    public uint UserData32 { get => userData32; set => userData32 = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#reserved
    /// </summary>
    internal uint Reserved { get => reserved; set => reserved = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#ledger
    /// </summary>
    public uint Ledger { get => ledger; set => ledger = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#code
    /// </summary>
    public ushort Code { get => code; set => code = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#flags
    /// </summary>
    public AccountFlags Flags { get => flags; set => flags = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account#timestamp
    /// </summary>
    public ulong Timestamp { get => timestamp; internal set => timestamp = value; }

}

[StructLayout(LayoutKind.Sequential, Size = SIZE)]
public struct Transfer
{
    public const int SIZE = 128;

    private UInt128 id;

    private UInt128 debitAccountId;

    private UInt128 creditAccountId;

    private UInt128 amount;

    private UInt128 pendingId;

    private UInt128 userData128;

    private ulong userData64;

    private uint userData32;

    private uint timeout;

    private uint ledger;

    private ushort code;

    private TransferFlags flags;

    private ulong timestamp;

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#id
    /// </summary>
    public UInt128 Id { get => id; set => id = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#debit_account_id
    /// </summary>
    public UInt128 DebitAccountId { get => debitAccountId; set => debitAccountId = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#credit_account_id
    /// </summary>
    public UInt128 CreditAccountId { get => creditAccountId; set => creditAccountId = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#amount
    /// </summary>
    public UInt128 Amount { get => amount; set => amount = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#pending_id
    /// </summary>
    public UInt128 PendingId { get => pendingId; set => pendingId = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#user_data_128
    /// </summary>
    public UInt128 UserData128 { get => userData128; set => userData128 = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#user_data_64
    /// </summary>
    public ulong UserData64 { get => userData64; set => userData64 = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#user_data_32
    /// </summary>
    public uint UserData32 { get => userData32; set => userData32 = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#timeout
    /// </summary>
    public uint Timeout { get => timeout; set => timeout = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#ledger
    /// </summary>
    public uint Ledger { get => ledger; set => ledger = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#code
    /// </summary>
    public ushort Code { get => code; set => code = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#flags
    /// </summary>
    public TransferFlags Flags { get => flags; set => flags = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/transfer#timestamp
    /// </summary>
    public ulong Timestamp { get => timestamp; internal set => timestamp = value; }

}

public enum CreateAccountResult : uint
{
    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#ok
    /// </summary>
    Ok = 0,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#linked_event_failed
    /// </summary>
    LinkedEventFailed = 1,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#linked_event_chain_open
    /// </summary>
    LinkedEventChainOpen = 2,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#timestamp_must_be_zero
    /// </summary>
    TimestampMustBeZero = 3,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#reserved_field
    /// </summary>
    ReservedField = 4,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#reserved_flag
    /// </summary>
    ReservedFlag = 5,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#id_must_not_be_zero
    /// </summary>
    IdMustNotBeZero = 6,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#id_must_not_be_int_max
    /// </summary>
    IdMustNotBeIntMax = 7,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#flags_are_mutually_exclusive
    /// </summary>
    FlagsAreMutuallyExclusive = 8,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#debits_pending_must_be_zero
    /// </summary>
    DebitsPendingMustBeZero = 9,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#debits_posted_must_be_zero
    /// </summary>
    DebitsPostedMustBeZero = 10,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#credits_pending_must_be_zero
    /// </summary>
    CreditsPendingMustBeZero = 11,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#credits_posted_must_be_zero
    /// </summary>
    CreditsPostedMustBeZero = 12,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#ledger_must_not_be_zero
    /// </summary>
    LedgerMustNotBeZero = 13,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#code_must_not_be_zero
    /// </summary>
    CodeMustNotBeZero = 14,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#exists_with_different_flags
    /// </summary>
    ExistsWithDifferentFlags = 15,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#exists_with_different_user_data_128
    /// </summary>
    ExistsWithDifferentUserData128 = 16,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#exists_with_different_user_data_64
    /// </summary>
    ExistsWithDifferentUserData64 = 17,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#exists_with_different_user_data_32
    /// </summary>
    ExistsWithDifferentUserData32 = 18,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#exists_with_different_ledger
    /// </summary>
    ExistsWithDifferentLedger = 19,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#exists_with_different_code
    /// </summary>
    ExistsWithDifferentCode = 20,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_accounts#exists
    /// </summary>
    Exists = 21,

}

public enum CreateTransferResult : uint
{
    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#ok
    /// </summary>
    Ok = 0,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#linked_event_failed
    /// </summary>
    LinkedEventFailed = 1,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#linked_event_chain_open
    /// </summary>
    LinkedEventChainOpen = 2,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#timestamp_must_be_zero
    /// </summary>
    TimestampMustBeZero = 3,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#reserved_flag
    /// </summary>
    ReservedFlag = 4,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#id_must_not_be_zero
    /// </summary>
    IdMustNotBeZero = 5,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#id_must_not_be_int_max
    /// </summary>
    IdMustNotBeIntMax = 6,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#flags_are_mutually_exclusive
    /// </summary>
    FlagsAreMutuallyExclusive = 7,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#debit_account_id_must_not_be_zero
    /// </summary>
    DebitAccountIdMustNotBeZero = 8,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#debit_account_id_must_not_be_int_max
    /// </summary>
    DebitAccountIdMustNotBeIntMax = 9,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#credit_account_id_must_not_be_zero
    /// </summary>
    CreditAccountIdMustNotBeZero = 10,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#credit_account_id_must_not_be_int_max
    /// </summary>
    CreditAccountIdMustNotBeIntMax = 11,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#accounts_must_be_different
    /// </summary>
    AccountsMustBeDifferent = 12,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#pending_id_must_be_zero
    /// </summary>
    PendingIdMustBeZero = 13,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#pending_id_must_not_be_zero
    /// </summary>
    PendingIdMustNotBeZero = 14,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#pending_id_must_not_be_int_max
    /// </summary>
    PendingIdMustNotBeIntMax = 15,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#pending_id_must_be_different
    /// </summary>
    PendingIdMustBeDifferent = 16,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#timeout_reserved_for_pending_transfer
    /// </summary>
    TimeoutReservedForPendingTransfer = 17,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#amount_must_not_be_zero
    /// </summary>
    AmountMustNotBeZero = 18,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#ledger_must_not_be_zero
    /// </summary>
    LedgerMustNotBeZero = 19,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#code_must_not_be_zero
    /// </summary>
    CodeMustNotBeZero = 20,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#debit_account_not_found
    /// </summary>
    DebitAccountNotFound = 21,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#credit_account_not_found
    /// </summary>
    CreditAccountNotFound = 22,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#accounts_must_have_the_same_ledger
    /// </summary>
    AccountsMustHaveTheSameLedger = 23,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#transfer_must_have_the_same_ledger_as_accounts
    /// </summary>
    TransferMustHaveTheSameLedgerAsAccounts = 24,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#pending_transfer_not_found
    /// </summary>
    PendingTransferNotFound = 25,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#pending_transfer_not_pending
    /// </summary>
    PendingTransferNotPending = 26,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#pending_transfer_has_different_debit_account_id
    /// </summary>
    PendingTransferHasDifferentDebitAccountId = 27,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#pending_transfer_has_different_credit_account_id
    /// </summary>
    PendingTransferHasDifferentCreditAccountId = 28,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#pending_transfer_has_different_ledger
    /// </summary>
    PendingTransferHasDifferentLedger = 29,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#pending_transfer_has_different_code
    /// </summary>
    PendingTransferHasDifferentCode = 30,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#exceeds_pending_transfer_amount
    /// </summary>
    ExceedsPendingTransferAmount = 31,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#pending_transfer_has_different_amount
    /// </summary>
    PendingTransferHasDifferentAmount = 32,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#pending_transfer_already_posted
    /// </summary>
    PendingTransferAlreadyPosted = 33,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#pending_transfer_already_voided
    /// </summary>
    PendingTransferAlreadyVoided = 34,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#pending_transfer_expired
    /// </summary>
    PendingTransferExpired = 35,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#exists_with_different_flags
    /// </summary>
    ExistsWithDifferentFlags = 36,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#exists_with_different_debit_account_id
    /// </summary>
    ExistsWithDifferentDebitAccountId = 37,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#exists_with_different_credit_account_id
    /// </summary>
    ExistsWithDifferentCreditAccountId = 38,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#exists_with_different_amount
    /// </summary>
    ExistsWithDifferentAmount = 39,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#exists_with_different_pending_id
    /// </summary>
    ExistsWithDifferentPendingId = 40,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#exists_with_different_user_data_128
    /// </summary>
    ExistsWithDifferentUserData128 = 41,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#exists_with_different_user_data_64
    /// </summary>
    ExistsWithDifferentUserData64 = 42,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#exists_with_different_user_data_32
    /// </summary>
    ExistsWithDifferentUserData32 = 43,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#exists_with_different_timeout
    /// </summary>
    ExistsWithDifferentTimeout = 44,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#exists_with_different_code
    /// </summary>
    ExistsWithDifferentCode = 45,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#exists
    /// </summary>
    Exists = 46,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#overflows_debits_pending
    /// </summary>
    OverflowsDebitsPending = 47,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#overflows_credits_pending
    /// </summary>
    OverflowsCreditsPending = 48,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#overflows_debits_posted
    /// </summary>
    OverflowsDebitsPosted = 49,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#overflows_credits_posted
    /// </summary>
    OverflowsCreditsPosted = 50,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#overflows_debits
    /// </summary>
    OverflowsDebits = 51,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#overflows_credits
    /// </summary>
    OverflowsCredits = 52,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#overflows_timeout
    /// </summary>
    OverflowsTimeout = 53,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#exceeds_credits
    /// </summary>
    ExceedsCredits = 54,

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/requests/create_transfers#exceeds_debits
    /// </summary>
    ExceedsDebits = 55,

}

[StructLayout(LayoutKind.Sequential, Size = SIZE)]
public struct CreateAccountsResult
{
    public const int SIZE = 8;

    private uint index;

    private CreateAccountResult result;

    public uint Index { get => index; set => index = value; }

    public CreateAccountResult Result { get => result; set => result = value; }

}

[StructLayout(LayoutKind.Sequential, Size = SIZE)]
public struct CreateTransfersResult
{
    public const int SIZE = 8;

    private uint index;

    private CreateTransferResult result;

    public uint Index { get => index; set => index = value; }

    public CreateTransferResult Result { get => result; set => result = value; }

}

[StructLayout(LayoutKind.Sequential, Size = SIZE)]
public struct AccountFilter
{
    public const int SIZE = 64;

    [StructLayout(LayoutKind.Sequential, Size = SIZE)]
    private unsafe struct ReservedData
    {
        public const int SIZE = 24;

        private fixed byte raw[SIZE];

        public byte[] GetData()
        {
            fixed (void* ptr = raw)
            {
                return new ReadOnlySpan<byte>(ptr, SIZE).ToArray();
            }
        }

        public void SetData(byte[] value)
        {
            if (value == null) throw new ArgumentNullException(nameof(value));
            if (value.Length != SIZE) throw new ArgumentException("Expected a byte[" + SIZE + "] array", nameof(value));

            fixed (void* ptr = raw)
            {
                value.CopyTo(new Span<byte>(ptr, SIZE));
            }
        }
    }

    private UInt128 accountId;

    private ulong timestampMin;

    private ulong timestampMax;

    private uint limit;

    private AccountFilterFlags flags;

    private ReservedData reserved;

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account-filter#account_id
    /// </summary>
    public UInt128 AccountId { get => accountId; set => accountId = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account-filter#timestamp_min
    /// </summary>
    public ulong TimestampMin { get => timestampMin; set => timestampMin = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account-filter#timestamp_max
    /// </summary>
    public ulong TimestampMax { get => timestampMax; set => timestampMax = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account-filter#limit
    /// </summary>
    public uint Limit { get => limit; set => limit = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account-filter#flags
    /// </summary>
    public AccountFilterFlags Flags { get => flags; set => flags = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account-filter#reserved
    /// </summary>
    internal byte[] Reserved { get => reserved.GetData(); set => reserved.SetData(value); }

}

[StructLayout(LayoutKind.Sequential, Size = SIZE)]
public struct AccountBalance
{
    public const int SIZE = 128;

    [StructLayout(LayoutKind.Sequential, Size = SIZE)]
    private unsafe struct ReservedData
    {
        public const int SIZE = 56;

        private fixed byte raw[SIZE];

        public byte[] GetData()
        {
            fixed (void* ptr = raw)
            {
                return new ReadOnlySpan<byte>(ptr, SIZE).ToArray();
            }
        }

        public void SetData(byte[] value)
        {
            if (value == null) throw new ArgumentNullException(nameof(value));
            if (value.Length != SIZE) throw new ArgumentException("Expected a byte[" + SIZE + "] array", nameof(value));

            fixed (void* ptr = raw)
            {
                value.CopyTo(new Span<byte>(ptr, SIZE));
            }
        }
    }

    private UInt128 debitsPending;

    private UInt128 debitsPosted;

    private UInt128 creditsPending;

    private UInt128 creditsPosted;

    private ulong timestamp;

    private ReservedData reserved;

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account-balances#debits_pending
    /// </summary>
    public UInt128 DebitsPending { get => debitsPending; set => debitsPending = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account-balances#debits_posted
    /// </summary>
    public UInt128 DebitsPosted { get => debitsPosted; set => debitsPosted = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account-balances#credits_pending
    /// </summary>
    public UInt128 CreditsPending { get => creditsPending; set => creditsPending = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account-balances#credits_posted
    /// </summary>
    public UInt128 CreditsPosted { get => creditsPosted; set => creditsPosted = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account-balances#timestamp
    /// </summary>
    public ulong Timestamp { get => timestamp; set => timestamp = value; }

    /// <summary>
    /// https://docs.tigerbeetle.com/reference/account-balances#reserved
    /// </summary>
    internal byte[] Reserved { get => reserved.GetData(); set => reserved.SetData(value); }

}

public enum InitializationStatus : uint
{
    Success = 0,

    Unexpected = 1,

    OutOfMemory = 2,

    AddressInvalid = 3,

    AddressLimitExceeded = 4,

    ConcurrencyMaxInvalid = 5,

    SystemResources = 6,

    NetworkSubsystem = 7,

}

public enum PacketStatus : byte
{
    Ok = 0,

    TooMuchData = 1,

    InvalidOperation = 2,

    InvalidDataSize = 3,

}

internal enum PacketAcquireStatus : uint
{
    Ok = 0,

    ConcurrencyMaxExceeded = 1,

    Shutdown = 2,

}

internal enum TBOperation : byte
{
    Pulse = 128,

    CreateAccounts = 129,

    CreateTransfers = 130,

    LookupAccounts = 131,

    LookupTransfers = 132,

    GetAccountTransfers = 133,

    GetAccountBalances = 134,

}

[StructLayout(LayoutKind.Sequential, Size = SIZE)]
internal unsafe struct TBPacket
{
    public const int SIZE = 64;

    [StructLayout(LayoutKind.Sequential, Size = SIZE)]
    private unsafe struct ReservedData
    {
        public const int SIZE = 8;

        private fixed byte raw[SIZE];

        public byte[] GetData()
        {
            fixed (void* ptr = raw)
            {
                return new ReadOnlySpan<byte>(ptr, SIZE).ToArray();
            }
        }

        public void SetData(byte[] value)
        {
            if (value == null) throw new ArgumentNullException(nameof(value));
            if (value.Length != SIZE) throw new ArgumentException("Expected a byte[" + SIZE + "] array", nameof(value));

            fixed (void* ptr = raw)
            {
                value.CopyTo(new Span<byte>(ptr, SIZE));
            }
        }
    }

    public TBPacket* next;

    public IntPtr userData;

    public byte operation;

    public PacketStatus status;

    public uint dataSize;

    public IntPtr data;

    public TBPacket* batchNext;

    public TBPacket* batchTail;

    public uint batchSize;

    private ReservedData reserved;

}

internal static class TBClient
{
    private const string LIB_NAME = "tb_client";

    [DllImport(LIB_NAME, CallingConvention = CallingConvention.Cdecl)]
    public static unsafe extern InitializationStatus tb_client_init(
        IntPtr* out_client,
        UInt128Extensions.UnsafeU128 cluster_id,
        byte* address_ptr,
        uint address_len,
        uint num_packets,
        IntPtr on_completion_ctx,
        delegate* unmanaged[Cdecl]<IntPtr, IntPtr, TBPacket*, byte*, uint, void> on_completion_fn
    );

    [DllImport(LIB_NAME, CallingConvention = CallingConvention.Cdecl)]
    public static unsafe extern InitializationStatus tb_client_init_echo(
        IntPtr* out_client,
        UInt128Extensions.UnsafeU128 cluster_id,
        byte* address_ptr,
        uint address_len,
        uint num_packets,
        IntPtr on_completion_ctx,
        delegate* unmanaged[Cdecl]<IntPtr, IntPtr, TBPacket*, byte*, uint, void> on_completion_fn
    );

    [DllImport(LIB_NAME, CallingConvention = CallingConvention.Cdecl)]
    public static unsafe extern PacketAcquireStatus tb_client_acquire_packet(
        IntPtr client,
        TBPacket** out_packet
    );

    [DllImport(LIB_NAME, CallingConvention = CallingConvention.Cdecl)]
    public static unsafe extern void tb_client_release_packet(
        IntPtr client,
        TBPacket* packet
    );

    [DllImport(LIB_NAME, CallingConvention = CallingConvention.Cdecl)]
    public static unsafe extern void tb_client_submit(
        IntPtr client,
        TBPacket* packet
    );

    [DllImport(LIB_NAME, CallingConvention = CallingConvention.Cdecl)]
    public static unsafe extern void tb_client_deinit(
        IntPtr client
    );
}

