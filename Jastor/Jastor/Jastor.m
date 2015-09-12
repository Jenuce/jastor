#import "Jastor.h"
#import "JastorRuntimeHelper.h"
#if !__has_feature(objc_arc)
#error NSString+JSONCategories must be built with ARC.
#endif
@implementation Jastor

@synthesize objectId;
Class nsDictionaryClass;
Class nsArrayClass;

+ (id)objectFromDictionary:(NSDictionary*)dictionary {
    id item = [[self alloc] initWithDictionary:dictionary];
    return item;
}
- (NSDictionary*)convertProperyRule{
    return @{@"objectId":@"id"};
}
- (id)initWithDictionary:(NSDictionary *)dictionary {
	if (!nsDictionaryClass) nsDictionaryClass = [NSDictionary class];
	if (!nsArrayClass) nsArrayClass = [NSArray class];
	NSDictionary* rule = [self convertProperyRule];
    NSString * tempRuleKey = nil;
	if ((self = [super init])) {
		for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
            tempRuleKey = [rule objectForKey:key];
            if (tempRuleKey == nil) {
                tempRuleKey = key;
            }
            id value = [dictionary valueForKey:tempRuleKey];
			
			if (value == [NSNull null] || value == nil) {
                continue;
            }
            
            if ([JastorRuntimeHelper isPropertyReadOnly:[self class] propertyName:key]) {
                continue;
            }
			
			// handle dictionary
			if ([value isKindOfClass:nsDictionaryClass]) {
				Class klass = [JastorRuntimeHelper propertyClassForPropertyName:key ofClass:[self class]];
				value = [[klass alloc] initWithDictionary:value];
			}
			// handle array
			else if ([value isKindOfClass:nsArrayClass]) {
				
				NSMutableArray *childObjects = [NSMutableArray arrayWithCapacity:[(NSArray*)value count]];
				
				for (id child in value) {
                    if ([[child class] isSubclassOfClass:nsDictionaryClass]) {
                        
                        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@_class", key]);
                        if ([[self class] methodForSelector:selector] != nil) {
                            Class arrayItemType = ((Class (*)(id, SEL))[[self class] methodForSelector:selector])([self class], selector);
                            if ([arrayItemType isSubclassOfClass:[NSDictionary class]]) {
                                [childObjects addObject:child];
                            } else if ([arrayItemType isSubclassOfClass:[Jastor class]]) {
                                Jastor *childDTO = [[arrayItemType alloc] initWithDictionary:child];
                                [childObjects addObject:childDTO];
                            }
                        }
					} else {
						[childObjects addObject:child];
					}
				}
				
				value = childObjects;
			}
			// handle all others
			[self setValue:value forKey:key];
		}
	}
	return self;	
}

- (void)dealloc {
	self.objectId = nil;
	
	for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
		[self setValue:nil forKey:key];
	}
	
}

- (void)encodeWithCoder:(NSCoder*)encoder {
    NSDictionary* rule = [self convertProperyRule];
    NSString * tempRuleKey = nil;
	for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
        tempRuleKey = [rule objectForKey:key];
        if (tempRuleKey == nil) {
            tempRuleKey = key;
        }
		[encoder encodeObject:[self valueForKey:key] forKey:tempRuleKey];
	}
}

- (id)initWithCoder:(NSCoder *)decoder {
	if ((self = [super init])) {
        NSDictionary* rule = [self convertProperyRule];
        NSString * tempRuleKey = nil;
		for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
            if ([JastorRuntimeHelper isPropertyReadOnly:[self class] propertyName:key]) {
                continue;
            }
            tempRuleKey = [rule objectForKey:key];
            if (tempRuleKey == nil) {
                tempRuleKey = key;
            }
			id value = [decoder decodeObjectForKey:tempRuleKey];
			if (value != [NSNull null] && value != nil) {
				[self setValue:value forKey:key];
			}
		}
	}
	return self;
}

- (NSMutableDictionary *)toDictionary {
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    NSDictionary* rule = [self convertProperyRule];
    NSString * tempRuleKey = nil;
	for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
        tempRuleKey = [rule objectForKey:key];
        if (tempRuleKey == nil) {
            tempRuleKey = key;
        }
		id value = [self valueForKey:key];
        if (value && [value isKindOfClass:[Jastor class]]) {            
            [dic setObject:[value toDictionary] forKey:tempRuleKey];
        } else if (value && [value isKindOfClass:[NSArray class]] && ((NSArray*)value).count > 0) {
            id internalValue = [value objectAtIndex:0];
            if (internalValue && [internalValue isKindOfClass:[Jastor class]]) {
                NSMutableArray *internalItems = [NSMutableArray array];
                for (id item in value) {
                    [internalItems addObject:[item toDictionary]];
                }
                [dic setObject:internalItems forKey:tempRuleKey];
            } else {
                [dic setObject:value forKey:tempRuleKey];
            }
        } else if (value != nil) {
            [dic setObject:value forKey:tempRuleKey];
        }
	}
    return dic;
}

- (NSString *)description {
    NSMutableDictionary *dic = [self toDictionary];
	
	return [NSString stringWithFormat:@"#<%@: id = %@ %@>", [self class], self.objectId, [dic description]];
}

- (BOOL)isEqual:(id)object {
	if (object == nil || ![object isKindOfClass:[Jastor class]]) return NO;
	
	Jastor *model = (Jastor *)object;
	
	return [self.objectId isEqualToString:model.objectId];
}

@end
