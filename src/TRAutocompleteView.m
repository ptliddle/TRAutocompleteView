//
// Copyright (c) 2013, Taras Roshko
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// The views and conclusions contained in the software and documentation are those
// of the authors and should not be interpreted as representing official policies,
// either expressed or implied, of the FreeBSD Project.
//

#import <BlocksKit/UIView+BlocksKit.h>
#import <BlocksKit/UIGestureRecognizer+BlocksKit.h>
#import "TRAutocompleteView.h"
#import "TRAutocompleteItemsSource.h"
#import "TRAutocompletionCellFactory.h"

@interface TRAutocompleteView () <UITableViewDelegate, UITableViewDataSource>

@property(readwrite) id <TRSuggestionItem> selectedSuggestion;
@property(readwrite) NSArray *suggestions;

@end

@implementation TRAutocompleteView
{
    BOOL _visible;

    __weak UITextField *_queryTextField;
    __weak UIViewController *_contextController;

    UITableView *_table;
    id <TRAutocompleteItemsSource> _itemsSource;
    id <TRAutocompletionCellFactory> _cellFactory;

    BOOL _showAllOptions;
}

+ (TRAutocompleteView *)autocompleteViewBindedTo:(UITextField *)textField
                                     usingSource:(id <TRAutocompleteItemsSource>)itemsSource
                                     cellFactory:(id <TRAutocompletionCellFactory>)factory
                                    presentingIn:(UIViewController *)controller
{
    return [[TRAutocompleteView alloc] initWithFrame:CGRectZero
                                           textField:textField
                                         itemsSource:itemsSource
                                         cellFactory:factory
                                          controller:controller
                           showAllOptionsOnBeginEdit:NO];
}

+ (TRAutocompleteView *)autocompleteViewBindedTo:(UITextField *)textField
                                     usingSource:(id <TRAutocompleteItemsSource>)itemsSource
                                     cellFactory:(id <TRAutocompletionCellFactory>)factory
                                    presentingIn:(UIViewController *)controller
                                    showAllOptionsOnBeginEdit:(BOOL)showAllOptionsOnBeginEdit
{
    return [[TRAutocompleteView alloc] initWithFrame:CGRectZero
                                           textField:textField
                                         itemsSource:itemsSource
                                         cellFactory:factory
                                          controller:controller
                           showAllOptionsOnBeginEdit:showAllOptionsOnBeginEdit];
}

- (id)initWithFrame:(CGRect)frame
          textField:(UITextField *)textField
        itemsSource:(id <TRAutocompleteItemsSource>)itemsSource
        cellFactory:(id <TRAutocompletionCellFactory>)factory
         controller:(UIViewController *)controller
        showAllOptionsOnBeginEdit:(BOOL)showAllOptionsOnBeginEdit
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self loadDefaults];

        _showAllOptions = showAllOptionsOnBeginEdit;

        _queryTextField = textField;
        _itemsSource = itemsSource;
        _cellFactory = factory;
        _contextController = controller;

        if (itemsSource.numberOfSections > 1) {
            _table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        }
        else {
            _table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        }

        _table.backgroundColor = [UIColor clearColor];
        _table.separatorColor = self.separatorColor;
        _table.separatorStyle = self.separatorStyle;
        _table.delegate = self;
        _table.dataSource = self;

        //With this option enabled all the options will be shown when the user clicks the bound textfield
        if(_showAllOptions){
            //Add tap gesture recogniser to table view to stop taps going to superview
            UITapGestureRecognizer *tableTapRecognizer = [[UITapGestureRecognizer alloc] init];
            [tableTapRecognizer setCancelsTouchesInView:NO];
            [_table addGestureRecognizer:tableTapRecognizer];

            //Add notifications for begin edit
            [[NSNotificationCenter defaultCenter]
                    addObserver:self
                       selector:@selector(queryChanged:)
                           name:UITextFieldTextDidBeginEditingNotification
                         object:_queryTextField];
        }

        [[NSNotificationCenter defaultCenter]
                               addObserver:self
                                  selector:@selector(queryChanged:)
                                      name:UITextFieldTextDidChangeNotification
                                    object:_queryTextField];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];

        [self addSubview:_table];
    }

    return self;
}

- (void)loadDefaults
{
    self.backgroundColor = [UIColor whiteColor];

    self.separatorColor = [UIColor lightGrayColor];
    self.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.topMargin = 0;
}

- (void)keyboardWasShown:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    CGFloat contextViewHeight = 0;
    CGFloat kbHeight = 0;
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
    {
        contextViewHeight = _contextController.view.frame.size.height;
        kbHeight = kbSize.height;
    }
    else if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
    {
        contextViewHeight = _contextController.view.frame.size.width;
        kbHeight = kbSize.width;
    }

    CGPoint queryTextOrigin = _queryTextField.frame.origin;

    //if the textField is not a direct subview of the context controller then convert coordinates
    if(![[_contextController.view subviews] containsObject:_queryTextField]){
        queryTextOrigin = [_contextController.view convertPoint:_queryTextField.frame.origin fromView:_queryTextField.superview];
    }

    CGFloat calculatedY = queryTextOrigin.y + _queryTextField.frame.size.height + self.topMargin;
    CGFloat calculatedHeight = contextViewHeight - calculatedY - kbHeight;

    calculatedHeight += _contextController.tabBarController.tabBar.frame.size.height; //keyboard is shown over it, need to compensate

    self.frame = CGRectMake(queryTextOrigin.x,
                            calculatedY,
                            _queryTextField.frame.size.width,
                            calculatedHeight);
    _table.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [self removeFromSuperview];
    _visible = NO;
}

- (void)queryChanged:(id)sender
{
    if ([_queryTextField.text length] >= _itemsSource.minimumCharactersToTrigger)
    {
        [_itemsSource itemsFor:_queryTextField.text whenReady:
                                                            ^(NSArray *suggestions)
                                                            {
                                                                if (_queryTextField.text.length
                                                                    < _itemsSource.minimumCharactersToTrigger)
                                                                {
                                                                    self.suggestions = nil;
                                                                    [_table reloadData];
                                                                }
                                                                else
                                                                {
                                                                    self.suggestions = suggestions;
                                                                    [_table reloadData];

                                                                    if (self.suggestions.count > 0 && !_visible)
                                                                    {
                                                                        [_contextController.view addSubview:self];
                                                                        _visible = YES;
                                                                    }
                                                                }
                                                            }];
    }
    else
    {
        self.suggestions = nil;
        [_table reloadData];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([_itemsSource respondsToSelector:@selector(numberOfSections)]) {
        return _itemsSource.numberOfSections;
    }
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return _itemsSource.sectionTitles[(NSUInteger) section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_itemsSource.numberOfSections > 1) {
        return ((NSArray *) self.suggestions[(NSUInteger) section]).count;
    }
    else {
        return self.suggestions.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"TRAutocompleteCell";

    id cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
        cell = [_cellFactory createReusableCellWithIdentifier:identifier];

    NSAssert([cell isKindOfClass:[UITableViewCell class]], @"Cell must inherit from UITableViewCell");
    NSAssert([cell conformsToProtocol:@protocol(TRAutocompletionCell)], @"Cell must conform TRAutocompletionCell");
    UITableViewCell <TRAutocompletionCell> *completionCell = (UITableViewCell <TRAutocompletionCell> *) cell;

    id suggestion = [self getSuggestion:indexPath];

    NSAssert([suggestion conformsToProtocol:@protocol(TRSuggestionItem)], @"Suggestion item must conform TRSuggestionItem");
    id <TRSuggestionItem> suggestionItem = (id <TRSuggestionItem>) suggestion;

    [completionCell updateWith:suggestionItem];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id suggestion = [self getSuggestion:indexPath];

    NSAssert([suggestion conformsToProtocol:@protocol(TRSuggestionItem)], @"Suggestion item must conform TRSuggestionItem");

    self.selectedSuggestion = (id <TRSuggestionItem>) suggestion;

    _queryTextField.text = self.selectedSuggestion.completionText;
    [_queryTextField resignFirstResponder];

    if (self.didAutocompleteWith)
        self.didAutocompleteWith(self.selectedSuggestion);
}

- (id)getSuggestion:(NSIndexPath *)indexPath {
    if (_itemsSource.numberOfSections > 1) {
        return self.suggestions[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
    }
    else {
        return self.suggestions[(NSUInteger) indexPath.row];
    }
}

- (void)dealloc
{
    if(_showAllOptions){
        [[NSNotificationCenter defaultCenter]
                removeObserver:self
                          name:UITextFieldTextDidBeginEditingNotification
                        object:nil];
    }

    [[NSNotificationCenter defaultCenter]
                           removeObserver:self
                                     name:UITextFieldTextDidChangeNotification
                                   object:nil];
    [[NSNotificationCenter defaultCenter]
                           removeObserver:self
                                     name:UIKeyboardDidShowNotification
                                   object:nil];
    [[NSNotificationCenter defaultCenter]
                           removeObserver:self
                                     name:UIKeyboardWillHideNotification
                                   object:nil];
}

@end