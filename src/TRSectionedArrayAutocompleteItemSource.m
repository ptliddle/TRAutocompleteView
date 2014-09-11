//
// Created by MacBook on 15/07/2014.
//

#import <BlocksKit/NSArray+BlocksKit.h>
#import "TRSectionedArrayAutocompleteItemSource.h"
#import "TRGoogleMapsSuggestion.h"
#import "NSArray+Functional.h"
#import "NSDictionary+BlocksKit.h"
#import "TRHighightedMatchSuggestion.h"


@implementation TRSectionedArrayAutocompleteItemSource
{
    NSDictionary *sections;
    int minimumCharacters;
    BOOL caseSensitive;
}

-(id)initWithSectionedItems:(NSDictionary *)theSectionedItems andMinimumCharactersToTrigger:(int)minChars{
    return [self initWithSectionedItems:theSectionedItems minimumCharactersToTrigger:minChars andHighlighting:NO];
}

-(id)initWithSectionedItems:(NSDictionary *)theSectionedItems minimumCharactersToTrigger:(int)minChars andHighlighting:(BOOL)enableHighlighting{
    self = [super self];

    if(self){
        minimumCharacters = minChars;
        sections = theSectionedItems;
        _highlightColor = [UIColor yellowColor];
        _highlightMatchedText = enableHighlighting;
    }

    return self;
}



- (NSUInteger)minimumCharactersToTrigger {
    return (NSUInteger)minimumCharacters;
}

-(NSArray *)findItemsMatchingQueryAsIndexedArray:(NSString *)query {
    __block NSMutableArray *filteredItems = [[NSMutableArray alloc] init];
    if([query length] > 0) {
        [sections bk_each:^(NSString *key, NSArray *items) {
            NSArray *matchedItems = (NSArray *)[items reduceUsingBlock:^id(NSArray *aggregation, NSString *curItem) {
                NSRange matchRange = [self matchedStringRange:query item:curItem];
                if(matchRange.location != NSNotFound){
                    NSMutableAttributedString *matchedString = [[NSMutableAttributedString alloc] initWithString:curItem];

                    if(_highlightMatchedText)
                        [matchedString addAttribute:NSForegroundColorAttributeName value:_highlightColor range:matchRange];

                    return [aggregation arrayByAddingObject:matchedString];
                }
                return aggregation;
            } initialAggregation:@[]];
            [filteredItems addObject:matchedItems];
        }];
    }
    return filteredItems;
}

- (NSRange)matchedStringRange:(NSString *)query item:(id)item {
    NSRange matchRange;
    if(!caseSensitive){
            matchRange = [item rangeOfString:query options:NSCaseInsensitiveSearch];
    }
    else{
        matchRange = [item rangeOfString:query];
    }
    return matchRange;
}

-(NSArray *)allItemsAsIndexedArray {
    NSMutableArray *allResults = [[NSMutableArray alloc] init];
    [sections bk_each:^(id key, NSArray *items) {
        NSArray *mappedItems = [items bk_map:^id(NSString *item) {
            return [[NSMutableAttributedString alloc] initWithString:item];
        }];
        [allResults addObject:mappedItems];
    }];
    return allResults;
}

- (void)itemsFor:(NSString *)query whenReady:(void (^)(NSArray *))suggestionsReady {

    NSArray *filteredItems = nil;
    NSArray *searchResults = nil;

    if(sections.allKeys.count <= 0 ){
        filteredItems = @[NSLocalizedString(@"Loading...", @"Still loading items")];
    }
    else{
        if([query length] > 0){
            filteredItems = [self findItemsMatchingQueryAsIndexedArray:query];
        }
        else{
            filteredItems = [self allItemsAsIndexedArray];
        }
    }
    
    filteredItems = [self checkIfWeHaveResultsMatchingQuery:filteredItems];
    searchResults = [self convertToSuggestionsArray:filteredItems];

    suggestionsReady(searchResults);
}

- (NSArray *)convertToSuggestionsArray:(NSArray *)filteredItems {
    NSArray *searchResults = [filteredItems bk_map:^id(id result) {
        if([result isKindOfClass:[NSArray class]]){
            NSArray *newItems = [result bk_map:^id(NSAttributedString *curItem) {
                return [[TRHighightedMatchSuggestion alloc] initWith:curItem];
            }];
            return newItems;
        }
        else{
            return [[TRHighightedMatchSuggestion alloc] initWith:result];
        }
    }];
    return searchResults;
}

- (NSArray *)checkIfWeHaveResultsMatchingQuery:(NSArray *)filteredItems {
    if(!filteredItems || [filteredItems count] <= 0){
        filteredItems = @[NSLocalizedString(@"No results matching query", @"No results matching query")];
    }
    return filteredItems;
}

- (NSUInteger)numberOfSections {
    return sections.allKeys.count;
}

- (NSArray *)sectionTitles{
    return sections.allKeys;
}

@end