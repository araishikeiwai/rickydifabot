class RickyDifaBot::ExpenseManager
  BUDGETS = $gql.parse <<-gql
      query($year: Int!, $month: Int!) {
        budgets(year: $year, month: $month) {
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

  KEYBOARDS = [
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
          res << "#{budget.owner.name[0]}/#{budget.label}: <b>#{budget.amount_remaining.formatted}</b> (#{budget.amount_total.formatted})"
        else
          res << "#{budget.owner.name[0]}/#{budget.label}: #{budget.amount_remaining.formatted} + #{budget.amount_used.formatted} (#{budget.amount_total.formatted})"
        end
      end

      res.join("\n")
    end
  end
end
