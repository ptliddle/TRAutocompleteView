//
//  TRHighightedMatchSuggestion.m
//  Pods
//
//  Created by MacBook on 16/07/2014.
//
//

#import "TRHighightedMatchSuggestion.h"

@implementation TRHighightedMatchSuggestion

@synthesize suggestion = _suggestion;

- (id)initWith:(NSAttributedString *)theSuggestion {
    self = [super init];
    if(self){
        self.suggestion = theSuggestion;
    }
    return self;
}

- (NSString *)completionText {
    return self.suggestion.string;
}

- (NSAttributedString *)completionTextAsAttributedString{
    return self.suggestion;
}

@end
