//
//  TRHighightedMatchSuggestion.h
//  Pods
//
//  Created by MacBook on 16/07/2014.
//
//

#import <Foundation/Foundation.h>
#import "TRAutocompleteItemsSource.h"

@interface TRHighightedMatchSuggestion : NSObject <TRSuggestionItem>

@property (nonatomic, strong) NSAttributedString *suggestion;

- (id)initWith:(NSAttributedString *)theSuggestion;

@end
