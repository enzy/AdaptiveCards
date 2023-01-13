//
//  ACRInputChoiceSetRenderer
//  ACRInputChoiceSetRenderer.mm
//
//  Copyright © 2018 Microsoft. All rights reserved.
//

#import "ACRInputChoiceSetRenderer.h"
#import "ACOBaseCardElementPrivate.h"
#import "ACOHostConfigPrivate.h"
#import "ACRChoiceSetCompactStyleView.h"
#import "ACRChoiceSetTypeaheadSearchView.h"
#import "ACRChoiceSetViewDataSource.h"
#import "ACRInputLabelViewPrivate.h"
#import "ACRInputTableView.h"
#import "ChoiceSetInput.h"
#import "ChoicesData.h"
#import "UtiliOS.h"

@implementation ACRInputChoiceSetRenderer

+ (ACRInputChoiceSetRenderer *)getInstance
{
    static ACRInputChoiceSetRenderer *singletonInstance = [[self alloc] init];
    return singletonInstance;
}

+ (ACRCardElementType)elemType
{
    return ACRChoiceSetInput;
}

- (UIView *)render:(UIView<ACRIContentHoldingView> *)viewGroup
           rootView:(ACRView *)rootView
             inputs:(NSMutableArray *)inputs
    baseCardElement:(ACOBaseCardElement *)acoElem
         hostConfig:(ACOHostConfig *)acoConfig;
{
    std::shared_ptr<HostConfig> config = [acoConfig getHostConfig];
    std::shared_ptr<BaseCardElement> elem = [acoElem element];
    std::shared_ptr<ChoiceSetInput> choiceSet = std::dynamic_pointer_cast<ChoiceSetInput>(elem);
    ACRInputLabelView *inputLabelView = nil;
    const auto style = choiceSet->GetChoiceSetStyle();
    if (!choiceSet->GetIsMultiSelect() && (style == ChoiceSetStyle::Compact || style == ChoiceSetStyle::Filtered)) {
        ACRChoiceSetCompactStyleView *compactStyleView = [[ACRChoiceSetCompactStyleView alloc] initWithInputChoiceSet:acoElem rootView:rootView hostConfig:acoConfig];
        inputLabelView = [[ACRInputLabelView alloc] initInputLabelView:rootView acoConfig:acoConfig adaptiveInputElement:choiceSet inputView:compactStyleView accessibilityItem:compactStyleView viewGroup:viewGroup dataSource:nil];
    } else {
        ACRInputTableView *choiceSetView = [[ACRInputTableView alloc] initWithSuperview:viewGroup];
        choiceSetView.frame = CGRectMake(0, 0, viewGroup.frame.size.width, viewGroup.frame.size.height);

        [choiceSetView registerClass:[ACRChoiceSetCell class] forCellReuseIdentifier:checkedCheckboxReuseID];
        [choiceSetView registerClass:[ACRChoiceSetCell class] forCellReuseIdentifier:uncheckedCheckboxReuseID];
        [choiceSetView registerClass:[ACRChoiceSetCell class] forCellReuseIdentifier:checkedRadioButtonReuseID];
        [choiceSetView registerClass:[ACRChoiceSetCell class] forCellReuseIdentifier:uncheckedRadioButtonReuseID];
        NSObject<UITableViewDelegate, UITableViewDataSource, ACRIBaseInputHandler> *dataSource = [[ACRChoiceSetViewDataSource alloc] initWithInputChoiceSet:choiceSet WithHostConfig:config];
        ((ACRChoiceSetViewDataSource *)dataSource).spacing = choiceSetView.inputTableViewSpacing;
        [choiceSetView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

        // removes leading padding
        choiceSetView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        choiceSetView.delegate = dataSource;
        choiceSetView.dataSource = dataSource;

        inputLabelView = [[ACRInputLabelView alloc] initInputLabelView:rootView acoConfig:acoConfig adaptiveInputElement:choiceSet inputView:choiceSetView accessibilityItem:choiceSetView viewGroup:viewGroup dataSource:dataSource];
        choiceSetView.isAccessibilityElement = NO;
        choiceSetView.shouldGroupAccessibilityChildren = YES;
    }

    [inputs addObject:inputLabelView];

    [viewGroup addArrangedSubview:inputLabelView];

    return inputLabelView;
}

/// override this method to configure the styles of UI
- (void)configure:(UIView *)view
           rootView:(ACRView *)rootView
    baseCardElement:(ACOBaseCardElement *)acoElem
         hostConfig:(ACOHostConfig *)acoConfig;
{
    std::shared_ptr<BaseCardElement> elem = [acoElem element];
    std::shared_ptr<ChoiceSetInput> choiceSet = std::dynamic_pointer_cast<ChoiceSetInput>(elem);
    if (!choiceSet) {
        return;
    }
    const auto style = choiceSet->GetChoiceSetStyle();
    if (style == ChoiceSetStyle::Compact || style == ChoiceSetStyle::Filtered) {
        ACRChoiceSetCompactStyleView *choiceSetView = (ACRChoiceSetCompactStyleView *)view;
        choiceSetView.borderStyle = UITextBorderStyleRoundedRect;
        choiceSetView.backgroundColor = UIColor.systemGroupedBackgroundColor;
        // adjusting the right layout margins of the ACRChoiceSetCompactStyleView
        // can position showFilteredListControl
        UIButton *button = (UIButton *)choiceSetView.showFilteredListControl;

        // configure icons for the showFilteredListControl.
        if (@available(iOS 13.0, *)) {
            [button setImage:[UIImage systemImageNamed:@"chevron.down"] forState:UIControlStateNormal];
            [button setImage:[UIImage systemImageNamed:@"chevron.up"] forState:UIControlStateSelected];
        } else {
            [button setImage:[UIImage imageNamed:@"chevrondown"] forState:UIControlStateNormal];
            [button setImage:[UIImage imageNamed:@"chevronup"] forState:UIControlStateSelected];
        };

        UITableView *filteredListView = (UITableView *)choiceSetView.filteredListView;
        filteredListView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        filteredListView.cellLayoutMarginsFollowReadableWidth = false;
        // left contentInset aligns leading edge of the filteredListView
        filteredListView.contentInset = UIEdgeInsetsMake(0, 10, 0, 0);
        // for custom styling of the cell, please register a custom class here as shown below
        // and use the same reuse ID.
        [filteredListView registerClass:[ACRChoiceSetCell class] forCellReuseIdentifier:@"filterred-cell"];

        choiceSetView.spacingBottom = 10.0f;
    }
}
/// override this method to configure the styles of UI
- (void)configureUI:(UIViewController *)view
           rootView:(ACRView *)rootView
    baseCardElement:(ACOBaseCardElement *)acoElem
         hostConfig:(ACOHostConfig *)acoConfig
{
    std::shared_ptr<BaseCardElement> elem = [acoElem element];
    std::shared_ptr<ChoiceSetInput> choiceSet = std::dynamic_pointer_cast<ChoiceSetInput>(elem);
    if (!choiceSet) {
        return;
    }
    const auto style = choiceSet->GetChoiceSetStyle();
    std::shared_ptr<ChoicesData> choicesData = choiceSet->GetChoicesData();
    if (choicesData->GetChoicesDataType().compare((AdaptiveCardSchemaKeyToString(AdaptiveCardSchemaKey::DataQuery))) == 0 ) {
        ACRChoiceSetTypeaheadSearchView *typeaheadSearchView = (ACRChoiceSetTypeaheadSearchView *)view;
        
        UITextField *_customSearchBar = (UITextField *)typeaheadSearchView.searchBar;
        [_customSearchBar.heightAnchor constraintEqualToConstant:36].active = YES;
        _customSearchBar.textColor = [UIColor colorWithRed:0.431 green:0.431 blue:0.431 alpha:1];
        _customSearchBar.backgroundColor = [UIColor colorWithRed:0.945 green:0.945 blue:0.945 alpha:1];
        _customSearchBar.layer.cornerRadius = 10;
        _customSearchBar.borderStyle = UITextBorderStyleRoundedRect;
        
        UIView *_customSearchBarSeparator = (UIView *)typeaheadSearchView.searchBarSeparator;
        _customSearchBarSeparator.layer.backgroundColor = [[UIColor colorWithRed:0.784 green:0.784 blue:0.784 alpha:1] CGColor];
        [_customSearchBarSeparator.heightAnchor constraintEqualToConstant:0.5].active = YES;
        
        UITableView *filteredListView = (UITableView *)typeaheadSearchView.filteredListView;
        [filteredListView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        filteredListView.rowHeight = UITableViewAutomaticDimension;
        [filteredListView registerClass:UITableViewCell.self forCellReuseIdentifier:@"SauceCell"];
        
        UILabel *searchStateTitleLabel = (UILabel *)typeaheadSearchView.searchStateTitleLabel;
        searchStateTitleLabel.backgroundColor = [UIColor whiteColor];
        searchStateTitleLabel.textColor = [UIColor colorWithRed:0.443 green:0.443 blue:0.443 alpha:1];
        searchStateTitleLabel.alpha = 0.9;
        searchStateTitleLabel.textAlignment = NSTextAlignmentCenter;
        searchStateTitleLabel.font = [UIFont fontWithName:@"SegoeUI-Regular" size:16];
        [searchStateTitleLabel.heightAnchor constraintEqualToConstant:20].active = YES;
        
        UIActivityIndicatorView *loader = (UIActivityIndicatorView *)typeaheadSearchView.loader;
        [loader.heightAnchor constraintEqualToConstant:32].active = YES;
        [loader.widthAnchor constraintEqualToConstant:32].active = YES;
    }
}
@end
