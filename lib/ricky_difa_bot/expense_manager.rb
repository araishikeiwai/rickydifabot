class RickyDifaBot::ExpenseManager
  BUDGETS = $gql.parse <<-gql
    query($year: Int!, $month: Int!) {
      budgets(year: $year, month: $month) {
        id
        owner {
          name
        }
        label
        amountUsed {
          formatted
        }
        amountTotal {
          formatted
        }
        amountRemaining {
          formatted
        }
      }
    }
  gql

  MUTATIONS = $gql.parse <<-gql
    query($accountId: ID, $budgetId: ID, $first: Int) {
      mutations(accountId: $accountId, budgetId: $budgetId, first: $first) {
        nodes {
          datetime
          amount {
            formatted
          }
          aite {
            name
          }
          category {
            slug
          }
          account {
            slug
          } 
          type
        }
      }
    }
  gql

  ACCOUNTS = $gql.parse <<-gql
    query {
      accounts {
        id
        currency
        form
        slug
        balance {
          raw
          formatted
        }
      }
    }
  gql

  KEYBOARDS = [
    ['Accounts'],
    ['Remaining Budget']
  ]

  class << self
    def budgets(year: nil, month: nil)
      month ||= DateTime.now.month

      unless year
        year = DateTime.now.year
        if month > DateTime.now.month
          year -=  1
        end
      end

      resp = $gql.query(BUDGETS, variables: { year: year, month: month })

      current = year == DateTime.now.year && month == DateTime.now.month
      txt_label = current ? 'Remaining budgets' : 'Budgets'

      res = []
      res << "#{txt_label} for #{Date.new(year, month).strftime("%B %Y")}"
      res << "remaining + used (total)" unless current
      res << ""
      resp.data.budgets.each do |budget|
        if current
          res << "#{budget.owner.name[0]}/#{budget.label}: <b>#{budget.amount_remaining.formatted}</b> (#{budget.amount_total.formatted}) /mtx_b#{budget.id}"
        else
          res << "#{budget.owner.name[0]}/#{budget.label}: #{budget.amount_remaining.formatted} + #{budget.amount_used.formatted} (#{budget.amount_total.formatted}) /mtx_b#{budget.id}"
        end
      end

      res << ""
      res << "See more: https://araishikeiwai.com/expense_manager/budgets?month=#{month}&year=#{year}"

      res.join("\n")
    end

    def mutations(account_id: nil, budget_id: nil)
      resp = $gql.query(MUTATIONS, variables: { accountId: account_id, budgetId: budget_id, first: 10 })

      res = []
      res << "Last 10 mutations"
      res << ""
      resp.data.mutations.nodes.each do |mutation|
        tmp = "#{DateTime.parse(mutation.datetime).strftime("%b/%d")}: <b>#{mutation.amount.formatted}</b>"
        tmp += " in #{mutation.account.slug}" unless account_id
        tmp += " to #{mutation.aite.name}" if mutation.type == 'ExpenseManager::Debit'
        tmp += " from #{mutation.aite.name}" if mutation.type == 'ExpenseManager::Credit'
        tmp += " for #{mutation.category.slug}"
        res << tmp
      end

      res << ""
      url = 'https://araishikeiwai.com/expense_manager/mutations?tabular_view=true'
      url += "&account_id=#{account_id}" if account_id
      url += "&budget_id=#{budget_id}" if budget_id
      res << "See more: #{url}"

      res.join("\n")
    end

    def accounts
      resp = $gql.query(ACCOUNTS)

      res = []
      res << "List of accounts"
      res << ""
      resp.data.accounts.each do |account|
        next unless whitelist?(account)
        res << "<b>#{account.balance.formatted}</b> #{account.slug} /mtx_a#{account.id}"
      end
      res.join("\n")
    end

    private

    def  whitelist?(account)
      account.currency.in?(['CAD']) ||
        account.slug == 'Ricky-USD:E-Money:Virtual'
    end
  end
end
