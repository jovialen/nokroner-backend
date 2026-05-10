class TransactionService
  def initialize(transaction)
    @transaction = transaction
  end

  def perform
    ApplicationRecord.transaction do
      AccountBalanceService.change_at(@transaction.from,
        @transaction.date,
        -@transaction.amount
      ) if @transaction.from

      AccountBalanceService.change_at(@transaction.to,
        @transaction.date,
        @transaction.amount
      ) if @transaction.to
    end
  end

  def undo
    ApplicationRecord.transaction do
      AccountBalanceService.change_at(@transaction.from,
        @transaction.date,
        @transaction.amount
      ) if @transaction.from

      AccountBalanceService.change_at(@transaction.to,
        @transaction.date,
        -@transaction.amount
      ) if @transaction.to
    end
  end
end
