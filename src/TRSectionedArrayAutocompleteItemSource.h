//
// Created by MacBook on 15/07/2014.
//

#import <Foundation/Foundation.h>
#import "TRAutocompleteItemsSource.h"


@interface TRSectionedArrayAutocompleteItemSource : NSObject<TRAutocompleteItemsSource, TRSuggestionItem>

//This enables highlighting of the section of the item that was matched
@property (nonatomic) BOOL highlightMatchedText;
//This sets the color to highlight the matched text, defaults to yellow
@property (nonatomic, strong) UIColor *highlightColor;

-(id)initWithSectionedItems:(NSDictionary *)theSectionedItems minimumCharactersToTrigger:(int)minChars
            andHighlighting:(BOOL)enableHighlighting;
-(id)initWithSectionedItems:(NSDictionary *)theSectionedItems andMinimumCharactersToTrigger:(int)minChars;

@end