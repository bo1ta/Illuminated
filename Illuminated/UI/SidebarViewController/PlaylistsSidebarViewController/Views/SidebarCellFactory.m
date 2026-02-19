//
//  SidebarCellFactory.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import "SidebarCellFactory.h"

@implementation SidebarCellFactory

+ (nonnull NSTableCellView *)headerCellForOutlineView:(nonnull NSOutlineView *)outlineView title:(NSString *)title {
  NSTableCellView *cell = [outlineView makeViewWithIdentifier:SidebarCellTypeHeader owner:self];
  if (!cell) {
    cell = [[NSTableCellView alloc] init];
    cell.identifier = SidebarCellTypeHeader;

    NSTextField *textField = [[NSTextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.bordered = NO;
    textField.drawsBackground = NO;
    textField.editable = NO;
    textField.selectable = NO;
    textField.font = [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold];
    textField.textColor = [NSColor secondaryLabelColor];
    cell.textField = textField;
    [cell addSubview:textField];

    [NSLayoutConstraint activateConstraints:@[
      [textField.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor constant:16],
      [textField.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor constant:-16],
      [textField.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor constant:0]
    ]];
  }

  cell.textField.stringValue = [title uppercaseString];
  return cell;
}

+ (nonnull NSTableCellView *)itemCellForOutlineView:(nonnull NSOutlineView *)outlineView
                                              title:(nonnull NSString *)title
                                         systemIcon:(nullable NSString *)systemIcon {
  NSTableCellView *cell = [outlineView makeViewWithIdentifier:@"ItemCell" owner:self];
  if (!cell) {
    cell = [[NSTableCellView alloc] init];
    cell.identifier = @"ItemCell";
    cell.translatesAutoresizingMaskIntoConstraints = NO;

    NSImageView *imageView = [[NSImageView alloc] init];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    cell.imageView = imageView;
    [cell addSubview:imageView];

    NSTextField *textField = [[NSTextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.bordered = NO;
    textField.drawsBackground = NO;
    textField.maximumNumberOfLines = 1;
    textField.editable = NO;
    textField.selectable = NO;
    cell.textField = textField;
    [cell addSubview:textField];

    [NSLayoutConstraint activateConstraints:@[
      [cell.heightAnchor constraintEqualToConstant:24],
      [imageView.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor constant:16],
      [imageView.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor constant:0],
      [imageView.widthAnchor constraintEqualToConstant:16],
      [imageView.heightAnchor constraintEqualToConstant:16],

      [textField.leadingAnchor constraintEqualToAnchor:imageView.trailingAnchor constant:8],
      [textField.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor constant:-16],
      [textField.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor constant:0]
    ]];
  }

  cell.imageView.image = [NSImage imageWithSystemSymbolName:systemIcon accessibilityDescription:nil];
  cell.imageView.contentTintColor = [NSColor secondaryLabelColor];

  cell.textField.stringValue = title;
  cell.textField.editable = NO;
  cell.textField.selectable = NO;

  return cell;
}

@end
