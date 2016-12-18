require 'feature_helper'

feature 'Make an offer', js: true do
  given!(:user1) { create :user, username: 'Bob', email: 'bob@email.com' }
  given!(:user2) { create :user, username: 'Ken', email: 'ken@email.com' }
  given!(:trade_request1) do
    create :trade_request, :new_york,
      user: user1,
      name: 'My Trade',
      kind: 'sell',
      profit: '12'
  end
  given!(:trade_request2) do
    create :trade_request, :stamford,
      user: user2,
      name: "Another Guy's Trade",
      kind: 'sell',
      profit: '12'
  end
  given(:offer) { user1.offers.last }
  given!(:current_price) { stub_price(10) }

  context 'authenticated' do

    background do
      login_as user1
    end

    Steps 'I make my first offer and it is accepted' do
      When 'I visit the trade request page' do
        visit public_trade_request_path(trade_request2.id)
      end
      Then 'I should see the trade request' do
        within '.content' do
          should_see "Another Guy's Trade"
          should_see 'This person is selling Dash'
          should_see 'This person wants a 12% profit so the current sale price is $11.20'
          should_see 'The trade location is: Stamford'
          should_see 'Make Offer'
        end
      end
      When 'I click the Make Offer button' do
        click_link 'Make Offer'
      end
      Then 'I should see a success message on the same page' do
        should_see 'Offer successfully created. Please wait for a reply.'
        within '.content' do
          should_see "Another Guy's Trade"
          should_see 'This person is selling Dash'
          should_see 'This person wants a 12% profit so the current sale price is $11.20'
          should_see 'The trade location is: Stamford'
          within 'button.disabled' do
            should_see 'Make Offer'
          end
          should_see 'Offer pending...'
        end
      end
      And 'there is an pending offer' do
        expect(offer.status).to eq 'pending'
        expect(offer.trade_request_id).to eq trade_request2.id
      end
      When 'I navigate to my offers list page' do
        within '.nav' do
          click_link 'Offers'
        end
      end
      Then 'I should see this offer' do
        within '.content' do
          should_see 'Offers'
          within '.table-list .row:first-child' do
            should_see "Another Guy's Trade"
            should_see 'Pending'
          end
        end
      end
      And 'I should see an email link' do
        within '.table-list .row:first-child .actions' do
          should_not_see_element 'a[href="mailto:ken@email.com"]', text: 'Email'
          should_not_see 'Review'
        end
      end
      When 'I click on the trade View link' do
        within '.table-list .row:first-child .name' do
          click_link "Another Guy's Trade"
        end
      end
      Then 'I should see the trade request' do
        should_be_located "/t/#{trade_request2.id}"
        within '.content' do
          should_see "Another Guy's Trade"
          should_see 'This person is selling Dash'
          should_see 'This person wants a 12% profit so the current sale price is $11.20'
          should_see 'The trade location is: Stamford'
          within 'button.disabled' do
            should_see 'Make Offer'
          end
          should_see 'Offer pending...'
        end
      end
      When 'I logout' do
        logout
      end

      # ===== Login as User 2 ===== #

      And 'I login as the other user' do
        login_as user2
      end
      And 'I go to the trade requests page' do
        within '.nav' do
          click_link 'Trade Requests'
        end
      end
      Then 'I should see my trade request' do
        within '.table-list .row:first-child' do
          should_see "Another Guy's Trade"
          should_see '1 Offers'
        end
      end
      And 'I should not see the new offer details' do
        within '.table-list' do
          should_not_see 'Bob'
          should_not_see 'Pending'
        end
      end
      When 'I expand my trade request' do
        click_link "Another Guy's Trade"
      end
      Then 'I should see the new offer details' do
        within '.table-list' do
          should_see 'Bob'
          should_see 'Pending'
        end
        within '.table-list .row:last-child .actions' do
          should_see 'Approve'
          should_see 'Decline'
        end
      end
      When 'I approve the offer' do
        click_link 'Approve'
      end
      Then 'I should see success message' do
        should_see 'Offer approved.'
        within '.table-list .row:last-child' do
          should_see 'Approved'
        end
      end
      And 'I should be on the trade requests page with the TR expanded' do
        should_be_located trade_requests_path(expand: trade_request2.id)
      end
      And 'I should see an email link' do
        within '.table-list .row:last-child' do
          should_see_element 'a[href="mailto:bob@email.com"]', text: 'Email'
        end
      end
      And 'I should not see the approve/decline links' do
        within '.table-list .row:last-child .actions' do
          should_not_see 'Approve'
          should_not_see 'Decline'
        end
      end
      And 'I should see links to review the offer' do
        within '.table-list .row:last-child .actions' do
          should_see 'Review'
        end
      end
      When 'I click Review' do
        within '.table-list .row:last-child .actions' do
          find('span.link', text: 'Review').click
        end
      end
      Then 'I should see links to review the offer' do
        within '.table-list .row:last-child .actions' do
          should_see 'Positive'
          should_see 'Negative'
        end
      end
      When 'I click positive' do
        click_link 'Positive'
      end
      Then 'I see a success message' do
        should_see 'Review created successfully'
      end
      And 'I should be back on the trade requests list page' do
        should_be_located trade_requests_path(expand: trade_request2.id)
      end
      And 'I should see the confirmation that I have reivewed the trade' do
        within '.table-list .row:last-child' do
          should_see 'Reviewed'
        end
      end
      And 'I should not see the review links anymore' do
        within '.table-list .row:last-child .actions' do
          should_not_see 'Review'
        end
      end
      And 'There should be a review record' do
        expect(Review.count).to eq 1
        expect(Review.last.tone).to eq 'positive'
      end
      When 'I click on the username' do
        click_link 'Bob'
      end
      Then 'I should see bobs profile page' do
        within 'h1' do
          should_see 'Bob'
          should_be_located '/p/Bob'
        end
      end
      When 'I logout' do
        logout
      end

      # ===== Login as User 1 ===== #

      And 'I login as the other user' do
        login_as user1
      end
      When 'I navigate to my offers list page' do
        within '.nav' do
          click_link 'Offers'
        end
      end
      Then 'I should see this offer' do
        within '.content' do
          should_see 'Offers'
          within '.table-list .row:first-child' do
            should_see "Another Guy's Trade"
            should_see 'Approved'
          end
        end
      end
      And 'I should see an email link' do
        within '.table-list .row:first-child .actions' do
          should_see 'Review'
          should_see_element 'a[href="mailto:ken@email.com"]', text: 'Email'
        end
      end
      When 'I click Review' do
        within '.table-list .row:last-child .actions' do
          find('span.link', text: 'Review').click
        end
      end
      Then 'I should see links to review the trade' do
        within '.table-list .row:last-child .actions' do
          should_see 'Positive'
          should_see 'Negative'
        end
      end
      When 'I click Negative' do
        click_link 'Negative'
      end
      Then 'I see a success message' do
        should_see 'Review created successfully'
      end
      And 'I should be back on the offers page' do
        should_be_located offers_path
      end
      And 'I should see the confirmation that I have reivewed the trade' do
        within '.table-list .row:last-child' do
          should_see 'Reviewed'
        end
      end
      And 'I should not see the review links anymore' do
        within '.table-list .row:last-child .actions' do
          should_not_see 'Review'
        end
      end
      And 'There should be a review record' do
        expect(Review.count).to eq 2
        expect(Review.last.tone).to eq 'negative'
      end
    end

    Steps 'I make my first offer and it is declined' do
      When 'I visit the trade request page' do
        visit public_trade_request_path(trade_request2.id)
      end
      Then 'I should see the trade request' do
        within '.content' do
          should_see "Another Guy's Trade"
          should_see 'This person is selling Dash'
          should_see 'This person wants a 12% profit so the current sale price is $11.20'
          should_see 'The trade location is: Stamford'
          should_see 'Make Offer'
        end
      end
      When 'I click the Make Offer button' do
        click_link 'Make Offer'
      end
      Then 'I should see a success message on the same page' do
        should_see 'Offer successfully created. Please wait for a reply.'
        within '.content' do
          should_see "Another Guy's Trade"
          should_see 'This person is selling Dash'
          should_see 'This person wants a 12% profit so the current sale price is $11.20'
          should_see 'The trade location is: Stamford'
          within 'button.disabled' do
            should_see 'Make Offer'
          end
          should_see 'Offer pending...'
        end
      end
      And 'there is an pending offer' do
        expect(offer.status).to eq 'pending'
        expect(offer.trade_request_id).to eq trade_request2.id
      end
      When 'I navigate to my offers list page' do
        within '.nav' do
          click_link 'Offers'
        end
      end
      Then 'I should see this offer' do
        within '.content' do
          should_see 'Offers'
          within '.table-list .row:first-child' do
            should_see "Another Guy's Trade"
            should_see 'Pending'
          end
        end
      end
      And 'I should see an email link' do
        within '.table-list .row:first-child .actions' do
          should_not_see_element 'a[href="mailto:ken@email.com"]', text: 'Email'
          should_not_see 'Review'
        end
      end
      When 'I click on the trade View link' do
        within '.table-list .row:first-child .name' do
          click_link "Another Guy's Trade"
        end
      end
      Then 'I should see the trade request' do
        should_be_located "/t/#{trade_request2.id}"
        within '.content' do
          should_see "Another Guy's Trade"
          should_see 'This person is selling Dash'
          should_see 'This person wants a 12% profit so the current sale price is $11.20'
          should_see 'The trade location is: Stamford'
          within 'button.disabled' do
            should_see 'Make Offer'
          end
          should_see 'Offer pending...'
        end
      end
      When 'I logout' do
        logout
      end

      # ===== Login as User 2 ===== #

      And 'I login as the other user' do
        login_as user2
      end
      And 'I go to the trade requests page' do
        within '.nav' do
          click_link 'Trade Requests'
        end
      end
      Then 'I should see my trade request' do
        within '.table-list .row:first-child' do
          should_see "Another Guy's Trade"
          should_see '1 Offers'
        end
      end
      And 'I should not see the new offer details' do
        within '.table-list' do
          should_not_see 'Bob'
          should_not_see 'Pending'
        end
      end
      When 'I expand my trade request' do
        click_link "Another Guy's Trade"
      end
      Then 'I should see the new offer details' do
        within '.table-list' do
          should_see 'Bob'
          should_see 'Pending'
        end
        within '.table-list .row:last-child .actions' do
          should_see 'Approve'
          should_see 'Decline'
        end
      end
      When 'I approve the offer' do
        click_link 'Decline'
      end
      Then 'I should see success message' do
        should_see 'Offer declined.'
        within '.table-list .row:last-child' do
          should_see 'Declined'
        end
      end
      And 'I should be on the trade requests page with the TR expanded' do
        should_be_located trade_requests_path(expand: trade_request2.id)
      end
      And 'I should not see an email link' do
        within '.table-list .row:last-child' do
          should_not_see_element 'a[href="mailto:bob@email.com"]', text: 'Email'
        end
      end
      And 'I should not see the approve/decline links' do
        within '.table-list .row:last-child .actions' do
          should_not_see 'Approve'
          should_not_see 'Decline'
        end
      end
      And 'I should not see the review links anymore' do
        within '.table-list .row:last-child .actions' do
          should_not_see 'Review'
        end
      end
      When 'I logout' do
        logout
      end

      # ===== Login as User 1 ===== #

      And 'I login as the other user' do
        login_as user1
      end
      When 'I navigate to my offers list page' do
        within '.nav' do
          click_link 'Offers'
        end
      end
      Then 'I should see this offer' do
        within '.content' do
          should_see 'Offers'
          within '.table-list .row:first-child' do
            should_see "Another Guy's Trade"
            should_see 'Declined'
          end
        end
      end
      And 'I should not see an email link' do
        within '.table-list .row:first-child .actions' do
          should_not_see_element 'a[href="mailto:ken@email.com"]', text: 'Email'
        end
      end
    end
  end

  context 'offer exists' do
    given!(:offer) { create :offer, user: user1, trade_request: trade_request2 }

    background do
      login_as user2
    end

    Steps 'race condition on Accept button' do
      And 'I go to the trade requests page' do
        within '.nav' do
          click_link 'Trade Requests'
        end
      end
      Then 'I should see my trade request' do
        within '.table-list .row:first-child' do
          should_see "Another Guy's Trade"
          should_see '1 Offers'
        end
      end
      And 'I should not see the new offer details' do
        within '.table-list' do
          should_not_see 'Bob'
          should_not_see 'Pending'
        end
      end
      When 'I expand my trade request' do
        click_link "Another Guy's Trade"
      end
      Then 'I should see the new offer details' do
        within '.table-list' do
          should_see 'Bob'
          should_see 'Pending'
        end
        within '.table-list .row:last-child .actions' do
          should_see 'Approve'
          should_see 'Decline'
        end
      end
      When 'the offer is approved from another tab' do
        offer.update_attribute(:status, :approved)
      end
      And 'I approve the offer' do
        click_link 'Approve'
      end
      Then 'I should see trade requests list' do
        should_see 'Trade Requests'
        should_not_see 'Offer approved.'
      end
      And 'I should be on the trade requests page without the TR expanded' do
        should_be_located trade_requests_path
      end
    end
  end
end
