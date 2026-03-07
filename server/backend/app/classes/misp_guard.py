#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
MISP Guard Integration for SpyGuard
Filters and validates IOCs from MISP instances before adding to database

Based on misp-guard by MISP Project
https://github.com/MISP/misp-guard
"""

from typing import Dict, List, Optional, Set
import json
import logging
import re
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)


@dataclass
class MISPInstance:
    """Represents a MISP instance configuration"""
    id: str
    ip: str
    host: str
    port: int
    compartment_id: str
    affiliation: str = ""
    required_taxonomies: List[str] = field(default_factory=list)
    allowed_tags: Dict[str, List[str]] = field(default_factory=dict)
    blocked_tags: List[str] = field(default_factory=list)
    blocked_distribution_levels: List[str] = field(default_factory=list)
    blocked_sharing_groups_uuids: List[str] = field(default_factory=list)
    blocked_attribute_types: List[str] = field(default_factory=list)
    blocked_attribute_categories: List[str] = field(default_factory=list)
    blocked_object_types: List[str] = field(default_factory=list)


@dataclass
class CompartmentRule:
    """Defines which compartments can reach each other"""
    compartment_id: str
    can_reach: List[str]


class MISPGuard:
    """
    MISP IOC Filter for SpyGuard
    
    Applies filtering rules to IOCs from MISP instances to prevent
    unintentional leakage of sensitive threat intelligence data.
    
    Features:
    - Compartment-based filtering (VLAN-like isolation)
    - Tag-based filtering (required/allowed/blocked tags)
    - Distribution level enforcement
    - Sharing group blocking
    - Attribute type/category filtering
    """
    
    def __init__(self, config_path: Optional[str] = None):
        self.config_path = config_path
        self.config: Dict = {}
        self.instances: Dict[str, MISPInstance] = {}
        self.compartment_rules: Dict[str, List[str]] = {}
        self.allowlist_urls: Set[str] = set()
        self.allowlist_domains: Set[str] = set()
        
        if config_path:
            self.load_config(config_path)
    
    def load_config(self, config_path: str) -> bool:
        """Load MISP Guard configuration from JSON file"""
        try:
            with open(config_path, 'r') as f:
                self.config = json.load(f)
            
            # Parse instances
            self._parse_instances()
            
            # Parse compartment rules
            self._parse_compartment_rules()
            
            # Parse allowlist
            self._parse_allowlist()
            
            logger.info(f"MISP Guard configuration loaded from {config_path}")
            logger.info(f"Loaded {len(self.instances)} instances, "
                       f"{len(self.compartment_rules)} compartments")
            return True
            
        except Exception as e:
            logger.error(f"Failed to load MISP Guard config: {e}")
            return False
    
    def _parse_instances(self):
        """Parse MISP instances from config"""
        instances_config = self.config.get('instances', {})
        
        for instance_id, instance_data in instances_config.items():
            taxonomies_rules = instance_data.get('taxonomies_rules', {})
            
            instance = MISPInstance(
                id=instance_id,
                ip=instance_data.get('ip', ''),
                host=instance_data.get('host', ''),
                port=instance_data.get('port', 443),
                compartment_id=instance_data.get('compartment_id', ''),
                affiliation=instance_data.get('affiliation', ''),
                required_taxonomies=taxonomies_rules.get('required_taxonomies', []),
                allowed_tags=taxonomies_rules.get('allowed_tags', {}),
                blocked_tags=taxonomies_rules.get('blocked_tags', []),
                blocked_distribution_levels=instance_data.get('blocked_distribution_levels', []),
                blocked_sharing_groups_uuids=instance_data.get('blocked_sharing_groups_uuids', []),
                blocked_attribute_types=instance_data.get('blocked_attribute_types', []),
                blocked_attribute_categories=instance_data.get('blocked_attribute_categories', []),
                blocked_object_types=instance_data.get('blocked_object_types', [])
            )
            
            self.instances[instance_id] = instance
    
    def _parse_compartment_rules(self):
        """Parse compartment reachability rules"""
        compartments = self.config.get('compartments_rules', {}).get('can_reach', {})
        
        for compartment_id, reachable in compartments.items():
            self.compartment_rules[compartment_id] = reachable
    
    def _parse_allowlist(self):
        """Parse URL and domain allowlist"""
        allowlist = self.config.get('allowlist', {})
        self.allowlist_urls = set(allowlist.get('urls', []))
        self.allowlist_domains = set(allowlist.get('domains', []))
    
    def can_sync_instances(self, src_instance_id: str, dst_instance_id: str) -> bool:
        """
        Check if two MISP instances can sync with each other
        
        Args:
            src_instance_id: Source MISP instance ID
            dst_instance_id: Destination MISP instance ID
            
        Returns:
            bool: True if sync is allowed, False otherwise
        """
        src_instance = self.instances.get(src_instance_id)
        dst_instance = self.instances.get(dst_instance_id)
        
        if not src_instance or not dst_instance:
            logger.warning(f"Instance not found: {src_instance_id} or {dst_instance_id}")
            return False
        
        # Check compartment rules
        src_compartment = src_instance.compartment_id
        dst_compartment = dst_instance.compartment_id
        
        allowed_compartments = self.compartment_rules.get(src_compartment, [])
        
        if dst_compartment not in allowed_compartments:
            logger.info(f"Sync blocked: {src_instance_id} (compartment {src_compartment}) "
                       f"cannot reach {dst_instance_id} (compartment {dst_compartment})")
            return False
        
        return True
    
    def filter_ioc(self, ioc: Dict, instance_id: Optional[str] = None) -> Optional[Dict]:
        """
        Filter a single IOC based on MISP Guard rules
        
        Args:
            ioc: IOC dictionary with keys: type, value, tag, tlp, distribution, etc.
            instance_id: Optional MISP instance ID for instance-specific rules
            
        Returns:
            Dict or None: Filtered IOC if allowed, None if blocked
        """
        if not instance_id:
            return ioc  # No filtering if no instance specified
        
        instance = self.instances.get(instance_id)
        if not instance:
            return ioc  # No filtering if instance not found
        
        # Check distribution level
        distribution = str(ioc.get('distribution', ''))
        if distribution in instance.blocked_distribution_levels:
            logger.debug(f"IOC blocked: distribution level {distribution}")
            return None
        
        # Check sharing group UUID
        sharing_group_uuid = ioc.get('sharing_group_uuid', '')
        if sharing_group_uuid in instance.blocked_sharing_groups_uuids:
            logger.debug(f"IOC blocked: sharing group {sharing_group_uuid}")
            return None
        
        # Check tags
        ioc_tags = ioc.get('tags', [])
        if isinstance(ioc_tags, str):
            ioc_tags = [ioc_tags]
        
        for tag in ioc_tags:
            if tag in instance.blocked_tags:
                logger.debug(f"IOC blocked: blocked tag {tag}")
                return None
        
        # Check required taxonomies
        if instance.required_taxonomies:
            ioc_taxonomies = ioc.get('taxonomies', [])
            for required in instance.required_taxonomies:
                if required not in ioc_taxonomies:
                    logger.debug(f"IOC blocked: missing required taxonomy {required}")
                    return None
        
        # Check allowed tags per taxonomy
        for taxonomy, allowed_tags in instance.allowed_tags.items():
            if taxonomy in ioc.get('taxonomies', []):
                tag_match = False
                for tag in ioc_tags:
                    if tag.startswith(f"{taxonomy}:"):
                        if tag in allowed_tags:
                            tag_match = True
                        else:
                            logger.debug(f"IOC blocked: tag {tag} not in allowed list")
                            return None
        
        return ioc
    
    def filter_iocs_batch(self, iocs: List[Dict], 
                         instance_id: Optional[str] = None) -> List[Dict]:
        """
        Filter a batch of IOCs
        
        Args:
            iocs: List of IOC dictionaries
            instance_id: Optional MISP instance ID
            
        Returns:
            List[Dict]: Filtered list of IOCs
        """
        filtered = []
        blocked_count = 0
        
        for ioc in iocs:
            result = self.filter_ioc(ioc, instance_id)
            if result:
                filtered.append(result)
            else:
                blocked_count += 1
        
        logger.info(f"MISP Guard filtered {blocked_count}/{len(iocs)} IOCs "
                   f"({len(filtered)} allowed)")
        return filtered
    
    def is_url_allowed(self, url: str) -> bool:
        """Check if URL is in allowlist"""
        if url in self.allowlist_urls:
            return True
        
        # Check domain allowlist
        for domain in self.allowlist_domains:
            if domain in url:
                return True
        
        return False
    
    def validate_attribute_type(self, attr_type: str, 
                               instance_id: Optional[str] = None) -> bool:
        """
        Check if attribute type is allowed
        
        Args:
            attr_type: MISP attribute type (e.g., 'ip-dst', 'email', 'passport-number')
            instance_id: Optional MISP instance ID
            
        Returns:
            bool: True if allowed, False if blocked
        """
        if not instance_id:
            return True
        
        instance = self.instances.get(instance_id)
        if not instance:
            return True
        
        if attr_type in instance.blocked_attribute_types:
            logger.debug(f"Attribute type blocked: {attr_type}")
            return False
        
        return True
    
    def validate_attribute_category(self, category: str, 
                                   instance_id: Optional[str] = None) -> bool:
        """
        Check if attribute category is allowed
        
        Args:
            category: MISP attribute category (e.g., 'Network activity', 'Person')
            instance_id: Optional MISP instance ID
            
        Returns:
            bool: True if allowed, False if blocked
        """
        if not instance_id:
            return True
        
        instance = self.instances.get(instance_id)
        if not instance:
            return True
        
        if category in instance.blocked_attribute_categories:
            logger.debug(f"Attribute category blocked: {category}")
            return False
        
        return True
    
    def validate_object_type(self, obj_type: str, 
                            instance_id: Optional[str] = None) -> bool:
        """
        Check if object type is allowed
        
        Args:
            obj_type: MISP object type (e.g., 'person', 'file', 'network-socket')
            instance_id: Optional MISP instance ID
            
        Returns:
            bool: True if allowed, False if blocked
        """
        if not instance_id:
            return True
        
        instance = self.instances.get(instance_id)
        if not instance:
            return True
        
        if obj_type in instance.blocked_object_types:
            logger.debug(f"Object type blocked: {obj_type}")
            return False
        
        return True
    
    def get_compartment_summary(self) -> Dict[str, List[str]]:
        """Get summary of compartment reachability rules"""
        return dict(self.compartment_rules)
    
    def get_instance_summary(self) -> List[Dict]:
        """Get summary of configured MISP instances"""
        summary = []
        for instance_id, instance in self.instances.items():
            summary.append({
                'id': instance_id,
                'host': instance.host,
                'ip': instance.ip,
                'compartment': instance.compartment_id,
                'blocked_tags': instance.blocked_tags,
                'blocked_distribution_levels': instance.blocked_distribution_levels
            })
        return summary


# Integration with SpyGuard's existing MISP class
def filter_misp_iocs(iocs: List[Dict], misp_instance_id: str, 
                    config_path: Optional[str] = None) -> List[Dict]:
    """
    Convenience function to filter MISP IOCs using MISP Guard rules
    
    Args:
        iocs: List of IOCs from MISP
        misp_instance_id: ID of the MISP instance
        config_path: Path to MISP Guard config file
        
    Returns:
        List[Dict]: Filtered IOCs
    """
    if not config_path:
        return iocs  # No filtering without config
    
    guard = MISPGuard(config_path)
    return guard.filter_iocs_batch(iocs, misp_instance_id)
