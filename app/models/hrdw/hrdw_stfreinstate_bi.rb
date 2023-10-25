# frozen_string_literal: true

module Hrdw
  class HrdwStfreinstateBi < HrdwLocalTimeRecord
    self.table_name = 'HRDW.HRDW_STFREINSTATE_BI'

    scope :active, ->(code){ where(lastflag: 'Y') }
  end
end
