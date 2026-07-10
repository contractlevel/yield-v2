// @review - doc

Detail onchain compliance procedures for this protocol

share.mint does not kyc check the recipient because the parent vault is the only caller of share.mint, and already performs kyc checks on the user
