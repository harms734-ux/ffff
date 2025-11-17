return {
	PlaceObj('ModItemCode', {
		'name', "TonyTraderScript",
		'CodeFileName', "Code/TonyTraderScript.lua",
	}),
	PlaceObj('ModItemConversation', {
		AssignToGroup = "Tony",
		DefaultActor = "Tony",
		group = "Default",
		id = "Tony_Dialog",
		PlaceObj('ConversationPhrase', {
			Keyword = "Greeting",
			KeywordT = T(774381032385, --[[ModItemConversation Tony_Dialog KeywordT]] "Greeting"),
			Lines = {
				PlaceObj('ConversationLine', {
					Character = "Tony",
					Text = T(741477670890, --[[ModItemConversation Tony_Dialog Text voice:Tony section:Tony_Dialog keyword:Greeting]] "Hello"),
					param_bindings = false,
				}),
			},
			id = "Greeting",
			param_bindings = false,
		}),
		PlaceObj('ConversationPhrase', {
			Effects = {
				PlaceObj('ExecuteCode', {
					FuncCode = "TonyOpenShop()",
					param_bindings = false,
				}),
			},
			GoTo = "<end conversation>",
			Keyword = "Trade",
			KeywordT = T(626411925033, --[[ModItemConversation Tony_Dialog KeywordT]] "Trade"),
			Lines = {
				PlaceObj('ConversationLine', {
					Character = "Tony",
					Text = T(139193503196, --[[ModItemConversation Tony_Dialog Text voice:Tony section:Tony_Dialog keyword:Trade]] "Let's do business!"),
					param_bindings = false,
				}),
			},
			StoryBranchIcon = "conversation_trade",
			id = "Trade",
			param_bindings = false,
		}),
		PlaceObj('ConversationPhrase', {
			GoTo = "<end conversation>",
			Keyword = "Goodbye",
			KeywordT = T(557225474228, --[[ModItemConversation Tony_Dialog KeywordT]] "Goodbye"),
			Lines = {
				PlaceObj('ConversationLine', {
					Character = "Tony",
					Text = T(848952680580, --[[ModItemConversation Tony_Dialog Text voice:Tony section:Tony_Dialog keyword:Goodbye]] "Come back soon!"),
					param_bindings = false,
				}),
			},
			id = "Goodbye",
			param_bindings = false,
		}),
	}),
	PlaceObj('ModItemXTemplate', {
		__is_kind_of = "XDialog",
		group = "Zulu",
		id = "TonyTraderDialog",
		recreate_after_save = true,
		PlaceObj('XTemplateWindow', {
			'__context', function (parent, context) return context or {} end,
			'__class', "XDialog",
			'Id', "idTonyTrader",
			'ContextUpdateOnOpen', true,
			'OnContextUpdate', function (self, context, ...)
				if context.unit then
					self.selected_unit = context.unit
				end
				self:UpdateMoneyDisplay()
			end,
			'FocusOnOpen', "child",
		}, {
			PlaceObj('XTemplateWindow', {
				'__class', "XCameraLockLayer",
				'lock_id', "TonyTrader",
			}),
			PlaceObj('XTemplateLayer', {
				'__condition', function (parent, context) return not netInGame and not gv_SatelliteView end,
				'layer', "XPauseLayer",
				'PauseReason', "TonyTraderPause",
			}),
			PlaceObj('XTemplateFunc', {
				'name', "Open",
				'func', function (self, ...)
					if gv_SatelliteView then
						SetCampaignSpeed(0, GetUICampaignPauseReason("TonyTrader"))
					end
					local context = self:GetContext()
					self.selected_unit = context.unit or GetInventoryUnit()
					self.shopping_cart = {}
					TonyUpdateInventory()
					local retVal = XDialog.Open(self, ...)
					self:UpdateMoneyDisplay()
					self:UpdateCartDisplay()
					return retVal
				end,
			}),
			PlaceObj('XTemplateFunc', {
				'name', "OnDelete",
				'func', function (self, ...)
					if gv_SatelliteView then
						SetCampaignSpeed(nil, GetUICampaignPauseReason("TonyTrader"))
					end
				end,
			}),
			PlaceObj('XTemplateFunc', {
				'name', "Close",
				'func', function (self, ...)
					self:OnDelete()
					return XDialog.Close(self, ...)
				end,
			}),
			PlaceObj('XTemplateFunc', {
				name = "UpdateMoneyDisplay",
				func = function (self)
					-- PLAYER MONEY (YOUR $)
					local moneyElement = self:ResolveId("idMoneyAmount")
					if moneyElement then
						local money = g_Player_Cash_Amount or 0
						moneyElement:SetText("$" .. tostring(money))
					end
					
					-- TONY MONEY (TONY'S $)
					local tonyMoneyElement = self:ResolveId("idTonyMoney")
					if tonyMoneyElement then
						-- Still read from mod var unless you want to change this too
						local tonyMoney = tonumber(GetModVar("TonyTrader", "TonyMoney") or 15000)
						tonyMoneyElement:SetText("$" .. tostring(tonyMoney))
					end
				end
			}),
			PlaceObj('XTemplateFunc', {
				'name', "AddToCart",
				'func', function (self, itemData)
					if not self.shopping_cart then
						self.shopping_cart = {}
					end
					if not itemData or itemData.isSpacer then
						return
					end
					
					local found = false
					for _, cartItem in ipairs(self.shopping_cart) do
						if cartItem.id == itemData.id then
							cartItem.quantity = cartItem.quantity + 1
							found = true
							break
						end
					end
					
					if not found then
						table.insert(self.shopping_cart, {
							id = itemData.id,
							name = itemData.name,
							price = itemData.price,
							quantity = 1,
							data = itemData
						})
					end
					
					self:UpdateCartDisplay()
				end,
			}),
			PlaceObj('XTemplateFunc', {
				'name', "RemoveFromCart",
				'func', function (self, itemId)
					if not self.shopping_cart then return end
					
					for i, cartItem in ipairs(self.shopping_cart) do
						if cartItem.id == itemId then
							cartItem.quantity = cartItem.quantity - 1
							if cartItem.quantity <= 0 then
								table.remove(self.shopping_cart, i)
							end
							break
						end
					end
					
					self:UpdateCartDisplay()
				end,
			}),
			PlaceObj('XTemplateFunc', {
				'name', "ClearCart",
				'func', function (self)
					self.shopping_cart = {}
					self:UpdateCartDisplay()
				end,
			}),
			PlaceObj('XTemplateFunc', {
				'name', "GetCartItemCount",
				'func', function (self)
					local count = 0
					if self.shopping_cart then
						for _, cartItem in ipairs(self.shopping_cart) do
							count = count + cartItem.quantity
						end
					end
					return count
				end,
			}),
			PlaceObj('XTemplateFunc', {
				'name', "GetCartTotal",
				'func', function (self, ...)
					local total = 0
					if self.shopping_cart then
						for _, cartItem in ipairs(self.shopping_cart) do
							total = total + (cartItem.price * cartItem.quantity)
						end
					end
					return total
				end,
			}),
			PlaceObj('XTemplateFunc', {
				'name', "UpdateCartDisplay",
				'func', function (self)
					local cartList = self:ResolveId("idCartList")
					if cartList then
						cartList:DeleteChildren()
						if self.shopping_cart and #self.shopping_cart > 0 then
							for _, cartItem in ipairs(self.shopping_cart) do
								local itemWnd = XTemplateSpawn("XWindow", cartList)
								itemWnd:SetLayoutMethod("HList")
								itemWnd:SetDock("top")
								itemWnd:SetMinHeight(26)
								itemWnd:SetBackground(RGB(40, 35, 30))
								itemWnd:SetMargins(box(2, 2, 2, 2))
								
								local nameText = XTemplateSpawn("XText", itemWnd)
								nameText:SetDock("left")
								nameText:SetMinWidth(95)
								nameText:SetTextStyle("PDABrowserTextSmaller")
								local shortName = cartItem.name
								if #shortName > 11 then
									shortName = shortName:sub(1, 9) .. ".."
								end
								nameText:SetText(shortName)
								nameText:SetTextColor(RGB(220, 200, 170))
								nameText:SetPadding(box(3, 3, 2, 3))
								
								local qtyText = XTemplateSpawn("XText", itemWnd)
								qtyText:SetDock("left")
								qtyText:SetMinWidth(25)
								qtyText:SetTextStyle("PDABrowserTextSmaller")
								qtyText:SetText(string.format("x%d", cartItem.quantity))
								qtyText:SetTextColor(RGB(200, 200, 200))
								qtyText:SetPadding(box(2, 3, 2, 3))
								
								local priceText = XTemplateSpawn("XText", itemWnd)
								priceText:SetDock("left")
								priceText:SetMinWidth(55)
								priceText:SetTextStyle("PDABrowserTextSmaller")
								priceText:SetText(string.format("$%d", cartItem.price * cartItem.quantity))
								priceText:SetTextColor(RGB(100, 255, 100))
								priceText:SetPadding(box(2, 3, 2, 3))
								
								local removeBtn = XTemplateSpawn("XTextButton", itemWnd)
								removeBtn:SetDock("right")
								removeBtn:SetMinWidth(22)
								removeBtn:SetMinHeight(20)
								removeBtn:SetTextStyle("PDABrowserTextSmaller")
								removeBtn:SetText("-")
								removeBtn:SetBackground(RGB(80, 40, 40))
								removeBtn.cart_item_id = cartItem.id
								removeBtn.OnPress = function(btn)
									local dlg = GetDialog(btn)
									if dlg then
										dlg:RemoveFromCart(btn.cart_item_id)
									end
								end
								
								itemWnd:Open()
							end
						end
					end
					
					-- Update total price
					local totalText = self:ResolveId("idCartTotal")
					if totalText then
						totalText:SetText(string.format("TOTAL: $%d", self:GetCartTotal()))
					end
					
					-- Update item counter
					local counterText = self:ResolveId("idCartCounter")
					if counterText then
						local itemCount = self:GetCartItemCount()
						counterText:SetText(string.format("(%d items)", itemCount))
					end
				end,
			}),
			PlaceObj('XTemplateFunc', {
				'name', "BuyCart",
				'func', function (self)
					if not self.shopping_cart or #self.shopping_cart == 0 then
						CreateRealTimeThread(function()
							CreateMessageBox(terminal.desktop, T{"Empty Cart"}, T{"Shopping cart is empty!"}, T{"OK"})
						end)
						return
					end
					
					local totalCost = self:GetCartTotal()
					if g_TonyPlayerMoney < totalCost then
						CreateRealTimeThread(function()
							CreateMessageBox(
								terminal.desktop, 
								T{"Not enough money"}, 
								T{string.format("You need $%d, but only have $%d", totalCost, g_TonyPlayerMoney)}, 
								T{"OK"}
							)
						end)
						return
					end
					
					local itemCount = self:GetCartItemCount()
					
					-- Purchase all items in cart with silent mode
					CreateRealTimeThread(function()
						for _, cartItem in ipairs(self.shopping_cart) do
							for i = 1, cartItem.quantity do
								TonyBuyItem(cartItem.data, true) -- Pass true for silent mode
								Sleep(50) -- Small delay between purchases
							end
						end
						
						-- Show success message after all items are purchased
						Sleep(300)
						CreateMessageBox(
							terminal.desktop,
							T{"Purchase Complete!"},
							T{string.format("Successfully purchased %d items for $%d!", itemCount, totalCost)},
							T{"OK"}
						)
						
						-- Clear the cart after successful purchase
						Sleep(200)
						local dlg = GetDialog("TonyTraderDialog")
						if dlg then
							dlg.shopping_cart = {}
							dlg:UpdateCartDisplay()
							dlg:UpdateMoneyDisplay()
							dlg:RefreshUI()
						end
					end)
				end,
			}),
			PlaceObj('XTemplateFunc', {
				'name', "RefreshUI",
				'func', function (self, ...)
					CreateRealTimeThread(function()
						Sleep(100)
						local buyGrid = self:ResolveId("idBuyGrid")
						if buyGrid then
							buyGrid:RespawnContent()
						end
						self:UpdateMoneyDisplay()
					end)
				end,
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XImage",
				'ZOrder', 100,
				'Margins', box(150, 150, 150, 150),
				'Dock', "box",
				'DrawOnTop', true,
				'Image', "UI/Inventory/T_Backpack_Inventory_Container",
				'ImageFit', "stretch",
			}, {
				PlaceObj('XTemplateWindow', {
					'Margins', box(3, 3, 3, 3),
					'Dock', "box",
					'LayoutMethod', "HList",
					'LayoutHSpacing', 8,
				}, {
					PlaceObj('XTemplateWindow', {
						'Dock', "left",
						'MinWidth', 150,
						'MaxWidth', 150,
						'LayoutMethod', "VList",
						'Background', RGBA(20, 20, 20, 255),
					}, {
						PlaceObj('XTemplateWindow', {
							'Padding', box(5, 5, 5, 5),
							'Dock', "top",
							'MinHeight', 180,
							'MaxHeight', 180,
						}, {
							PlaceObj('XTemplateWindow', {
								'__class', "XImage",
								'Dock', "box",
								'Image', "Mod/k5TKYic/images/TonyCleanFace.png",
								'ImageFit', "height",
								'FrameEdgeColor', RGBA(249, 198, 62, 255),
								'FrameLeft', 5,
								'FrameTop', 5,
								'FrameRight', 5,
								'FrameBottom', 5,
							}),
							}),
						PlaceObj('XTemplateWindow', {
							'__class', "XText",
							'Padding', box(3, 3, 3, 3),
							'Dock', "top",
							'MinHeight', 20,
							'TextStyle', "PDABrowserText",
							'TextColor', RGBA(220, 180, 100, 255),
							'Translate', true,
							'Text', T(843666951122, --[[ModItemXTemplate TonyTraderDialog Text]] "TONY'S"),
							'TextHAlign', "center",
						}),
						PlaceObj('XTemplateWindow', {
							'Margins', box(4, 6, 4, 4),
							'Dock', "top",
							'MinHeight', 70,
							'LayoutMethod', "VList",
							'Background', RGBA(30, 25, 20, 255),
						}, {
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Padding', box(2, 2, 2, 1),
								'Dock', "top",
								'TextStyle', "AmbientLifeMarker",
								'TextColor', RGBA(150, 150, 150, 255),
								'Translate', true,
								'Text', T(--[[ModItemXTemplate TonyTraderDialog Text]] "YOUR $:"),
								'TextHAlign', "center",
							}),
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Id', "idMoneyAmount",
								'Padding', box(2, 1, 2, 2),
								'Dock', "top",
								'TextStyle', "PDABrowserText",
								'TextColor', RGBA(220, 200, 150, 255),
								'Text', T(--[[ModItemXTemplate TonyTraderDialog Text]] "$0"),
								'TextHAlign', "center",
							}),
							}),
						PlaceObj('XTemplateWindow', {
							'Margins', box(4, 4, 4, 4),
							'Dock', "top",
							'MinHeight', 70,
							'LayoutMethod', "VList",
							'Background', RGBA(30, 25, 20, 255),
						}, {
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Padding', box(2, 2, 2, 1),
								'Dock', "top",
								'TextStyle', "AmbientLifeMarker",
								'TextColor', RGBA(150, 150, 150, 255),
								'Translate', true,
								'Text', T(--[[ModItemXTemplate TonyTraderDialog Text]] "TONY'S $:"),
								'TextHAlign', "center",
							}),
							PlaceObj('XTemplateWindow', {
								'__class', "XText",
								'Id', "idTonyMoney",
								'Padding', box(2, 1, 2, 2),
								'Dock', "top",
								'TextStyle', "PDABrowserText",
								'TextColor', RGBA(100, 255, 100, 255),
								'Text', T(--[[ModItemXTemplate TonyTraderDialog Text]] "$15,000"),
								'TextHAlign', "center",
							}),
							}),
						}),
					PlaceObj('XTemplateWindow', {
						'Dock', "box",
						'Background', RGBA(25, 25, 25, 255),
					}, {
						PlaceObj('XTemplateWindow', {
							'Margins', box(6, 6, 6, 6),
							'Dock', "box",
							'LayoutMethod', "VList",
							'LayoutVSpacing', 4,
						}, {
							PlaceObj('XTemplateWindow', {
								'Dock', "top",
								'MinHeight', 28,
								'Background', RGBA(40, 35, 30, 255),
							}, {
								PlaceObj('XTemplateWindow', {
									'__class', "XText",
									'Dock', "box",
									'TextStyle', "InventoryBackpackTitle",
									'TextColor', RGBA(220, 180, 100, 255),
									'Translate', true,
									'Text', T(--[[ModItemXTemplate TonyTraderDialog Text]] "TONY'S WEAPON SHOP"),
									'TextHAlign', "center",
									'TextVAlign', "center",
								}),
								}),
							PlaceObj('XTemplateWindow', {
								'Dock', "box",
							}, {
								PlaceObj('XTemplateWindow', {
									'__class', "XScrollArea",
									'Id', "idBuyScrollArea",
									'Margins', box(4, 10, 4, 4),
									'Dock', "box",
									'VScroll', "idBuyScrollbar",
								}, {
									PlaceObj('XTemplateWindow', {
										'__context', function (parent, context) return TonyGetInventory() end,
										'__class', "XContentTemplate",
										'Id', "idBuyGrid",
										'Margins', box(5, 1, 0, 0),
										'LayoutMethod', "HWrap",
										'LayoutHSpacing', 12,
										'LayoutVSpacing', 6,
										'BorderColor', RGBA(255, 255, 255, 0),
										'RespawnOnContext', false,
									}, {
										PlaceObj('XTemplateForEach', {
											'array', function (parent, context) return context or {} end,
											'__context', function (parent, context, item, i, n) return item end,
											'run_after', function (child, context, item, i, n, last)
												child.item_data = item
												
												if item.isSpacer then
													-- Spacer - make it full width to force new row
													child:SetDock("top")
													child:SetMinWidth(500)
													child:SetMinHeight(28)
													child:SetMaxHeight(28)
													child:SetBackground(RGB(60, 50, 40))
													child:SetMargins(box(0, 6, 0, 2))
													
													local headerText = child:ResolveId("idSpacerText")
													if headerText then
														headerText:SetText("=== " .. item.name .. " ===")
													end
												else
													-- Regular item button
													local iconImg = child:ResolveId("idBuyItemIcon")
													if iconImg then
														local iconPath = TonyGetItemIcon(item.id)
														if iconPath then
															iconImg:SetImage(iconPath)
														end
													end
													
													local nameText = child:ResolveId("idBuyItemName")
													local priceText = child:ResolveId("idBuyItemPrice")
													
													if nameText then 
														local displayName = item.name or "Unknown"
														if #displayName > 12 then
															displayName = displayName:sub(1, 10) .. ".."
														end
														nameText:SetText(displayName)
													end
													
													if priceText then 
														local priceStr = string.format("$%d", item.price or 0)
														if item.price >= 1000 then
															priceStr = string.format("$%.1fk", item.price / 1000)
														end
														if item.stack then
															priceStr = priceStr .. " x" .. item.stack
														end
														priceText:SetText(priceStr)
													end
												end
											end,
										}, {
											PlaceObj('XTemplateWindow', {
												'__condition', function (parent, context) return context and context.isSpacer end,
											}, {
												PlaceObj('XTemplateWindow', {
													'__class', "XText",
													'Id', "idSpacerText",
													'Dock', "box",
													'TextStyle', "PDABrowserText",
													'TextColor', RGBA(255, 220, 100, 255),
													'Text', T(--[[ModItemXTemplate TonyTraderDialog Text]] "Category"),
													'TextHAlign', "center",
													'TextVAlign', "center",
												}),
												}),
											PlaceObj('XTemplateWindow', {
												'__condition', function (parent, context) return context and not context.isSpacer end,
												'__class', "XTextButton",
												'MinWidth', 100,
												'MinHeight', 95,
												'MaxWidth', 100,
												'MaxHeight', 95,
												'Background', RGBA(23, 25, 24, 255),
												'BackgroundRectGlowSize', 1,
												'BackgroundRectGlowColor', RGBA(40, 40, 40, 255),
												'FXMouseIn', "buttonRollover",
												'FXPress', "buttonPress",
												'RolloverBackground', RGBA(219, 137, 31, 255),
											}, {
												PlaceObj('XTemplateFunc', {
													'name', "OnPress(self, gamepad)",
													'func', function (self, gamepad)
														local itemData = self.item_data or self:GetContext()
														
														if not itemData or itemData.isSpacer then
															return
														end
														
														local dlg = GetDialog(self)
														if dlg then
															dlg:AddToCart(itemData)
														end
													end,
												}),
												PlaceObj('XTemplateWindow', {
													'LayoutMethod', "VList",
													'LayoutVSpacing', 1,
												}, {
													PlaceObj('XTemplateWindow', {
														'__class', "XImage",
														'Id', "idBuyItemIcon",
														'Padding', box(8, 8, 8, 8),
														'Dock', "box",
														'ImageFit', "width",
													}),
													PlaceObj('XTemplateWindow', {
														'__class', "XText",
														'Id', "idBuyItemPrice",
														'Padding', box(2, 1, 2, 2),
														'Dock', "bottom",
														'MinHeight', 16,
														'TextColor', RGBA(100, 255, 100, 255),
														'Text', T(--[[ModItemXTemplate TonyTraderDialog Text]] "$0"),
														'TextHAlign', "center",
													}),
													PlaceObj('XTemplateWindow', {
														'__class', "XText",
														'Id', "idBuyItemName",
														'Padding', box(2, 0, 2, 0),
														'Dock', "top",
														'MinHeight', 10,
														'TextStyle', "PDABobbyStore_SCP_16MB",
														'TextColor', RGBA(200, 180, 150, 255),
														'Text', T(--[[ModItemXTemplate TonyTraderDialog Text]] "Item"),
														'TextHAlign', "center",
													}),
													}),
												}),
											}),
										}),
									}),
								PlaceObj('XTemplateWindow', {
									'__class', "XZuluScroll",
									'Id', "idBuyScrollbar",
									'Margins', box(0, 0, 2, 0),
									'HAlign', "right",
									'Target', "idBuyScrollArea",
									'AutoHide', true,
								}),
								}),
							}),
						}),
					PlaceObj('XTemplateWindow', {
						'Dock', "right",
						'MinWidth', 220,
						'MaxWidth', 220,
						'Background', RGBA(25, 25, 25, 255),
					}, {
						PlaceObj('XTemplateWindow', {
							'Margins', box(6, 6, 6, 6),
							'Dock', "box",
							'LayoutMethod', "VList",
							'LayoutVSpacing', 4,
						}, {
							PlaceObj('XTemplateWindow', {
								'Dock', "top",
								'MinHeight', 28,
								'Background', RGBA(40, 35, 30, 255),
								'LayoutMethod', "HList",
							}, {
								PlaceObj('XTemplateWindow', {
									'__class', "XText",
									'Dock', "left",
									'MinWidth', 150,
									'TextStyle', "InventoryBackpackTitle",
									'TextColor', RGBA(255, 200, 100, 255),
									'Translate', true,
									'Text', T(--[[ModItemXTemplate TonyTraderDialog Text]] "SHOPPING CART"),
									'TextHAlign', "left",
									'TextVAlign', "center",
									'Padding', box(4, 0, 0, 0),
								}),
								PlaceObj('XTemplateWindow', {
									'__class', "XText",
									'Id', "idCartCounter",
									'Dock', "right",
									'MinWidth', 60,
									'TextStyle', "PDABrowserText",
									'TextColor', RGBA(150, 200, 255, 255),
									'Text', T(--[[ModItemXTemplate TonyTraderDialog Text]] "(0 items)"),
									'TextHAlign', "right",
									'TextVAlign', "center",
									'Padding', box(0, 0, 4, 0),
								}),
								}),
							PlaceObj('XTemplateWindow', {
								'Dock', "box",
							}, {
								PlaceObj('XTemplateWindow', {
									'__class', "XScrollArea",
									'Id', "idCartScrollArea",
									'Margins', box(4, 4, 4, 4),
									'Dock', "box",
									'VScroll', "idCartScrollbar",
								}, {
									PlaceObj('XTemplateWindow', {
										'__class', "XContentTemplate",
										'Id', "idCartList",
										'LayoutMethod', "VList",
										'LayoutVSpacing', 2,
									}),
									}),
								PlaceObj('XTemplateWindow', {
									'__class', "XZuluScroll",
									'Id', "idCartScrollbar",
									'Margins', box(0, 0, 2, 0),
									'HAlign', "right",
									'Target', "idCartScrollArea",
									'AutoHide', true,
								}),
								}),
							PlaceObj('XTemplateWindow', {
								'Dock', "bottom",
								'MinHeight', 105,
								'LayoutMethod', "VList",
								'Background', RGBA(35, 30, 25, 255),
							}, {
								PlaceObj('XTemplateWindow', {
									'__class', "XText",
									'Id', "idCartTotal",
									'Padding', box(4, 6, 4, 2),
									'Dock', "top",
									'MinHeight', 28,
									'TextStyle', "PDABrowserText",
									'TextColor', RGBA(255, 255, 100, 255),
									'Text', T(--[[ModItemXTemplate TonyTraderDialog Text]] "TOTAL: $0"),
									'TextHAlign', "center",
								}),
								PlaceObj('XTemplateWindow', {
									'__class', "XTextButton",
									'Id', "idBuyCartBtn",
									'Margins', box(8, 4, 8, 4),
									'Dock', "top",
									'MinHeight', 32,
									'Background', RGBA(80, 120, 60, 255),
									'FXMouseIn', "buttonRollover",
									'FXPress', "buttonPress",
									'RolloverBackground', RGBA(100, 150, 80, 255),
									'TextStyle', "InventoryBackpackTitle",
									'Text', T(--[[ModItemXTemplate TonyTraderDialog Text]] "BUY ALL"),
								}, {
									PlaceObj('XTemplateFunc', {
										'name', "OnPress(self, gamepad)",
										'func', function (self, gamepad)
											local dlg = GetDialog(self)
											if dlg then
												dlg:BuyCart()
											end
										end,
									}),
									}),
								PlaceObj('XTemplateWindow', {
									'__class', "XTextButton",
									'Id', "idClearCartBtn",
									'Margins', box(8, 0, 8, 6),
									'Dock', "top",
									'MinHeight', 28,
									'Background', RGBA(100, 60, 50, 255),
									'FXMouseIn', "buttonRollover",
									'FXPress', "buttonPress",
									'RolloverBackground', RGBA(120, 70, 60, 255),
									'TextStyle', "PDABrowserText",
									'Text', T(--[[ModItemXTemplate TonyTraderDialog Text]] "CLEAR CART"),
								}, {
									PlaceObj('XTemplateFunc', {
										'name', "OnPress(self, gamepad)",
										'func', function (self, gamepad)
											local dlg = GetDialog(self)
											if dlg then
												dlg:ClearCart()
											end
										end,
									}),
									}),
								}),
							}),
						}),
					}),
				PlaceObj('XTemplateWindow', {
					'Margins', box(0, 12, 12, 0),
					'HAlign', "right",
					'VAlign', "top",
				}, {
					PlaceObj('XTemplateWindow', {
						'__class', "XTextButton",
						'Id', "idCloseButton",
						'MinWidth', 26,
						'MinHeight', 26,
						'MaxWidth', 26,
						'MaxHeight', 26,
						'Background', RGBA(60, 50, 40, 255),
						'FXMouseIn', "buttonRollover",
						'FXPress', "buttonPress",
						'TextStyle', "InventoryBackpackTitle",
						'TextColor', RGBA(220, 200, 150, 255),
						'Text', T(--[[ModItemXTemplate TonyTraderDialog Text]] "Ã—"),
					}, {
						PlaceObj('XTemplateFunc', {
							'name', "OnPress(self, gamepad)",
							'func', function (self, gamepad)
								local dlg = GetDialog(self)
								if dlg then
									dlg:Close()
								end
							end,
						}),
						}),
					}),
				}),
			PlaceObj('XTemplateAction', {
				'ActionId', "CloseTrader",
				'ActionName', T(--[[ModItemXTemplate TonyTraderDialog ActionName]] "Close"),
				'ActionShortcut', "Escape",
				'ActionGamepad', "ButtonB",
				'OnAction', function (self, host, source, ...)
					if host then
						host:Close()
					end
				end,
			}),
			}),
	}),
}